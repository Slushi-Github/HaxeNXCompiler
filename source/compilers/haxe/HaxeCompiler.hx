// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.compilers.haxe;

import haxe.Rest;

/**
 * The HaxeCompiler class is used to compile the Haxe project.
 * 
 * Author: Slushi
 */
class HaxeCompiler extends BaseCompiler {
	/**
	 * Force debug mode for Haxe
	 */
    public static var forceDebugMode:Bool = false;

	/**
	 * The name of the HXML file
	 */
	private final hxmlFileName:String = "haxeHXML";

    override public function startCompiler(args:Rest<Dynamic>) {
        super.startCompiler(args);
        
		var reportStyle:String = ProjectFile.instance.config.errorReportingStyle;
		var validStyles = ["classic", "indent", "pretty"];
		var style = reportStyle.toLowerCase();
		if (style == "" || !Lambda.has(validStyles, style)) {
			Logger.log("haxeerrorReportingStyle in [HxNXProject.xml -> haxeerrorReportingStyle] is invalid (" + style + "), using [classic]... Available styles: " + validStyles.join(", "),
				WARNING);
			reportStyle = "classic";
		} else {
			reportStyle = style;
		}

        // make a temporal HXML
		try {
			var hxml:String = InternalAsset.HAXE_HXML;

			hxml = AssetUtils.replaceTag(hxml, "PROGRAM_VERSION", Main.VERSION);
			hxml = AssetUtils.replaceTag(hxml, "HAXE_SOURCE_PATH", ProjectFile.instance.config.sourcePath);
			hxml = AssetUtils.replaceTag(hxml, "HAXE_MAIN_CLASS_NAME", ProjectFile.instance.config.haxeMain);
			hxml = AssetUtils.replaceTag(hxml, "HAXE_REPORTING_STYLE", reportStyle);
			hxml = AssetUtils.replaceTag(hxml, "CPP_OUTPUT_PATH", ProjectFile.instance.config.cppOutput);
			hxml = AssetUtils.replaceTag(hxml, "SWITCH_PROJECT_NAME", ProjectFile.instance.config.switchProjectName);
			hxml = AssetUtils.replaceTag(hxml, "HAXE_LIBS", LibsManager.instance.generateAllHaxeLibsString());
			hxml = AssetUtils.replaceTag(hxml, "HAXE_DEFINES", ProjectFile.instance.generateHaxeDefsString() + LibsManager.instance.generateAllHaxeLibDefsString());
			hxml = AssetUtils.replaceTag(hxml, "HAXE_FLAGS", ProjectFile.instance.generateHaxeFlagsString() + LibsManager.instance.generateHxDefinesString());

			File.saveContent(CommandLineUtils.getPathFromCurrentTerminal() + '/${hxmlFileName}.hxml', hxml);
        }
		catch (e) {
			Logger.exitBecauseError("Error creating [" + hxmlFileName + "]: " + e);
		}

		var debugMode:Bool = forceDebugMode ? true : (ProjectFile.instance.config.haxeDebug == true);

		Logger.log("Compiling \x1b[38;5;214mHaxe\033[0m project...\n------------------", PROCESSING);

		var startTime:Float = Sys.time();
		var compileProcessResult:Int = 0;

		if (debugMode) {
			compileProcessResult = Sys.command("haxe", ['${hxmlFileName}.hxml', '--debug']);
		} else {
			compileProcessResult = Sys.command("haxe", ['${hxmlFileName}.hxml']);
		}

		if (compileProcessResult != 0) {
			Logger.log("\x1b[38;5;1m------------------\033[0m", NONE);
		} else {
			Logger.log("\x1b[38;5;71m------------------\033[0m", NONE);
		}

		var endTime:Float = Sys.time();
		var elapsedTime:Float = endTime - startTime;
		var formattedTime:String = StringTools.trim(Math.fround(elapsedTime * 10) / 10 + "s");

		if (compileProcessResult != 0) {
			Logger.log("\x1b[38;5;214mHaxe\033[0m compilation failed", ERROR);
			exitCode = 1;
		}

		// delete temporal HXML file
		if (ProjectFile.instance.config.deleteTempFiles) {
			if (FileSystem.exists(CommandLineUtils.getPathFromCurrentTerminal() + '/${hxmlFileName}.hxml')) {
				FileSystem.deleteFile(CommandLineUtils.getPathFromCurrentTerminal() + '/${hxmlFileName}.hxml');
			}
		}

		if (exitCode == 0) {
			Logger.log('\x1b[38;5;214mHaxe\033[0m compilation successful in ${formattedTime}\n', SUCCESS);
		}
    }
}