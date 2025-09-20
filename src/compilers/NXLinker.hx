// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


package src.compilers;

import src.utils.LibsManager;
import src.compilers.HaxeCompiler;
import sys.io.File;
import sys.FileSystem;
import src.JsonFile;
import src.SlushiUtils;
import haxe.Resource;
import src.Main;
import src.utils.Defines;

using StringTools;

/**
 * The NXLinker class is used to link the project to Nintendo Switch
 * using [DevKitPro](https://devkitpro.org) MakeFile.
 * 
 * Author: Slushi.
 */
class NXLinker {
	static var jsonFile:JsonStruct = JsonFile.getJson();
	static var exitCodeNum:Int = 0;

	public static function init() {
		if (HaxeCompiler.getExitCode() != 0) {
			return;
		}

		if (jsonFile == null) {
			SlushiUtils.printMsg("Error loading [haxeNXConfig.json]", ERROR);
			return;
		}

		// Check if all required fields are set
		if (jsonFile.switchConfig.projectName == "") {
			SlushiUtils.printMsg("projectName in [haxeNXConfig.json -> switchConfig.projectName] is empty", ERROR);
			exitCodeNum = 3;
			return;
		}

		SlushiUtils.printMsg("Trying to compile to a \x1b[38;5;1mNintendo Switch\033[0m project -> \x1b[38;5;110m[" + jsonFile.switchConfig.projectName + "]\033[0m...", PROCESSING);

		SlushiUtils.printMsg("Creating Makefile...", PROCESSING);
		
		// Create a temporal Makefile with all required fields
		try {
			// Prepare Makefile
			var makefileContent:String = Resource.getString("MakefileNRO");
			makefileContent = makefileContent.replace("[PROGRAM_VERSION]", Main.version);
			makefileContent = makefileContent.replace("[PROJECT_NAME]", jsonFile.switchConfig.projectName);
			makefileContent = makefileContent.replace("[SOURCE_DIR]", jsonFile.haxeConfig.cppOutDir);

			SlushiUtils.printMsg("Creating hxcpp wrapper C++ file...", INFO);

			var wrapperCPPContent:String = Resource.getString("WrapperCodeCPP");

			if (!FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig.cppOutDir + "/wrapper_src")) {
				FileSystem.createDirectory(SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig.cppOutDir + "/wrapper_src");
			}

			if (!FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig.cppOutDir + "/wrapper_src/wrapper.cpp")) {
				SlushiUtils.printMsg("Creating hxcpp wrapper C++ file...", PROCESSING);
			} else {
				SlushiUtils.printMsg("Overwriting existing hxcpp wrapper C++ file...", WARN);
			}

			wrapperCPPContent = wrapperCPPContent.replace("[PROGRAM_VERSION]", Main.version);

			File.saveContent(SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig.cppOutDir + "/wrapper_src/wrapper.cpp", wrapperCPPContent);

			makefileContent = makefileContent.replace("[CPP_WRAPPER_DIR]", jsonFile.haxeConfig.cppOutDir + "/wrapper_src");

			SlushiUtils.printMsg("Created hxcpp wrapper C++ file! Continuing with the Makefile...", SUCCESS);

			makefileContent = makefileContent.replace("[LIBS]", parseMakeLibs());
			makefileContent = makefileContent.replace("[C_DEFINES]", parseMakeDefines().c);
			makefileContent = makefileContent.replace("[CPP_DEFINES]", parseMakeDefines().cpp);
			makefileContent = makefileContent.replace("[HAXE_MAIN_LIB]", jsonFile.haxeConfig.cppOutDir + "/libHAXE_NX_PROGRAM.a");

			if (!FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig.cppOutDir + "/switchFiles")) {
				FileSystem.createDirectory(SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig.cppOutDir + "/switchFiles");
			}
			makefileContent = makefileContent.replace("[OUT_DIR]", jsonFile.haxeConfig.cppOutDir + "/switchFiles");

			// Save Makefile
			// delete temporal makefile if already exists
			if (FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/Makefile")) {
				FileSystem.deleteFile(SlushiUtils.getPathFromCurrentTerminal() + "/Makefile");
				SlushiUtils.printMsg("Deleted existing [Makefile]", INFO);
			}

			File.saveContent(SlushiUtils.getPathFromCurrentTerminal() + "/Makefile", makefileContent);
			SlushiUtils.printMsg("Created Makefile", SUCCESS);
		} catch (e:Dynamic) {
			SlushiUtils.printMsg("Error creating Makefile: " + e, ERROR);
			exitCodeNum = 4;
			return;
		}

		SlushiUtils.printMsg("Compiling to ARM64/\x1b[38;5;1mNintendo Switch\033[0m...\n------------------", PROCESSING);

		var startTime:Float = Sys.time();
		var compileProcess = Sys.command("make");

		if (compileProcess != 0) {
			SlushiUtils.printMsg("\x1b[38;5;1m------------------\033[0m", NONE);
		} else {
			SlushiUtils.printMsg("\x1b[38;5;71m------------------\033[0m", NONE);
		}

		var endTime:Float = Sys.time();
		var elapsedTime:Float = endTime - startTime;
		var formattedTime:String = StringTools.trim(Math.fround(elapsedTime * 10) / 10 + "s");

		if (compileProcess != 0) {
			SlushiUtils.printMsg("\x1b[38;5;25mLinker\033[0m compilation failed", ERROR, "\n");
			exitCodeNum = 2;
		}

		// delete temporal makefile
		if (jsonFile.deleteTempFiles == true) {
			if (FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/Makefile")) {
				FileSystem.deleteFile(SlushiUtils.getPathFromCurrentTerminal() + "/Makefile");
			}
		}

		if (exitCodeNum == 0) {
			SlushiUtils.printMsg('\x1b[38;5;25mLinker\033[0m compilation successful. Check \033[4m[${jsonFile.haxeConfig.cppOutDir}/switchFiles]\033[0m, compilation time: ${formattedTime}\n',
				SUCCESS, "\n");
		}
	}

	public static function getExitCode():Int {
		return exitCodeNum;
	}

	static function parseMakeLibs():String {
		var libs = "";

		for (lib in LibsManager.parseCPPLibs()) {
			libs += lib + " ";
		}

		return libs;
	}

	static function parseMakeDefines():{c:String, cpp:String} {
		var defines = {c: "", cpp: ""};

		for (define in Defines.parseMakeFileDefines().main) {
			defines.c += define + " ";
		}

		defines.c += JsonFile.parseJSONVars();

		// These things absolutely have to go to the end.
		for (define in Defines.parseMakeFileDefines().c) {
			defines.c += define + " ";
		}

		for (define in Defines.parseMakeFileDefines().cpp) {
			defines.cpp += define + " ";
		}

		return defines;
	}
}
