// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.
package source.compilers.nx;

/**
 * The NXLinker class is used to link the nintendo Switch files from the Haxe project.
 * 
 * Author: Slushi
 */
class NXLinker extends BaseCompiler {
	override public function startCompiler(...args:Dynamic):Void {
		super.startCompiler(args);

		var maxJobs:Int = ProjectFile.instance.config.makeFileMaxJobs ?? 2;
		if (maxJobs <= 0) {
			maxJobs = 2;
		}

		// make a temporal MakeFile
		try {
			var makeFile = InternalAsset.MAKEFILE_NRO;

			makeFile = AssetUtils.replaceTag(makeFile, "PROGRAM_VERSION", Main.VERSION);
			makeFile = AssetUtils.replaceTag(makeFile, "SWITCH_PROJECT_NAME", ProjectFile.instance.config.switchProjectName);
			makeFile = AssetUtils.replaceTag(makeFile, "SOURCE_DIR", ProjectFile.instance.config.cppOutput);

			try {
				var wrapperCode = InternalAsset.WRAPPER_CODE_CPP;
				wrapperCode = AssetUtils.replaceTag(wrapperCode, "PROGRAM_VERSION", Main.VERSION);

				if (!FileSystem.exists(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/wrapper_src")) {
					FileSystem.createDirectory(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/wrapper_src");
				}

				File.saveContent(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/wrapper_src/wrapper.cpp",
					wrapperCode);
			} catch (e) {
				Logger.exitBecauseError("Error creating [wrapper.cpp]: " + e);
			}

			makeFile = AssetUtils.replaceTag(makeFile, "CPP_WRAPPER_DIR", ProjectFile.instance.config.cppOutput + "/wrapper_src");

			makeFile = AssetUtils.replaceTag(makeFile, "C_DEFINES",
				ProjectFile.instance.generateLinkerCDefines() + " " + ProjectFile.instance.generateCFlagsString() + " " + LibsManager.instance.generateCDefinesString());
			makeFile = AssetUtils.replaceTag(makeFile, "CPP_DEFINES",
				ProjectFile.instance.generateCppDefines() + " " + ProjectFile.instance.generateCppFlagsString() + " " + LibsManager.instance.generateCppDefinesString());
			makeFile = AssetUtils.replaceTag(makeFile, "LIBS", LibsManager.instance.generateSwitchLibsString());

			var haxeMainLib = ProjectFile.instance.config.cppOutput + "/libHAXE_NX_PROGRAM.a";
			if (HaxeCompiler.forceDebugMode) {
				haxeMainLib = ProjectFile.instance.config.cppOutput + "/libHAXE_NX_PROGRAM-debug.a";
			}
			makeFile = AssetUtils.replaceTag(makeFile, "HAXE_MAIN_LIB", haxeMainLib);

			if (!FileSystem.exists(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/switchFiles")) {
				FileSystem.createDirectory(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/switchFiles");
			}

			if (FileSystem.exists(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/SWITCH_ASSETS")) {
				FileSystem.createDirectory(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/SWITCH_ASSETS");
			}
			makeFile = AssetUtils.replaceTag(makeFile, "SWITCH_ASSETS_DIR", ProjectFile.instance.config.cppOutput + "/SWITCH_ASSETS");
			makeFile = AssetUtils.replaceTag(makeFile, "OUT_DIR", ProjectFile.instance.config.cppOutput + "/switchFiles");

			if (FileSystem.exists(CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/SWITCH_ASSETS/romfs")) {
				makeFile = AssetUtils.replaceTag(makeFile, "ROMFS_ARG", "ROMFS		:=	" + ProjectFile.instance.config.cppOutput + "/SWITCH_ASSETS/romfs");
			} else {
				makeFile = AssetUtils.replaceTag(makeFile, "ROMFS_ARG", "# NO ROMFS");
			}

			makeFile = AssetUtils.replaceTag(makeFile, "APP_TITLE", ProjectFile.instance.config.switchMeta.appTitle);
			makeFile = AssetUtils.replaceTag(makeFile, "APP_AUTHOR", ProjectFile.instance.config.switchMeta.appAuthor);
			makeFile = AssetUtils.replaceTag(makeFile, "APP_VERSION", ProjectFile.instance.config.switchMeta.appVersion);

			File.saveContent(CommandLineUtils.getPathFromCurrentTerminal() + "/Makefile", makeFile);
		} catch (e) {
			Logger.exitBecauseError("Error creating MakeFile: " + e);
		}

		Logger.log("Compiling to ARM64/\x1b[38;5;1mNintendo Switch\033[0m using " + maxJobs + " threads...\n------------------", PROCESSING);

		var startTime:Float = Sys.time();
		var compileProcess = Sys.command("make" + " -j" + maxJobs);

		if (compileProcess != 0) {
			Logger.log("\x1b[38;5;1m------------------\033[0m", NONE);
		} else {
			Logger.log("\x1b[38;5;71m------------------\033[0m", NONE);
		}

		var endTime:Float = Sys.time();
		var elapsedTime:Float = endTime - startTime;
		var formattedTime:String = StringTools.trim(Math.fround(elapsedTime * 10) / 10 + "s");

		if (compileProcess != 0) {
			Logger.log("\x1b[38;5;25mLinker\033[0m compilation failed", ERROR, "\n");
			exitCode = 1;
		}

		// delete temporal makefile
		if (ProjectFile.instance.config.deleteTempFiles == true) {
			if (FileSystem.exists(CommandLineUtils.getPathFromCurrentTerminal() + "/Makefile")) {
				FileSystem.deleteFile(CommandLineUtils.getPathFromCurrentTerminal() + "/Makefile");
			}
		}

		if (exitCode == 0) {
			Logger.log('\x1b[38;5;25mLinker\033[0m compilation successful in '
				+ formattedTime
				+ '. Check \033[4m[${ProjectFile.instance.config.cppOutput}/switchFiles]\033[0m\n',
				SUCCESS, "\n");
		}
	}
}
