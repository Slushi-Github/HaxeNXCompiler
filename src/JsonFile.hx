// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


package src;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import src.SlushiUtils;
import src.Main;

using StringTools;

/**
 * The main JSON file for the HaxeNXCompiler, contains the configuration of the project
 * like the libs, source directory, the output directory, the main class, etc.
 * 
 * Author: Slushi
 */

/**
 * The HaxeConfig is used to store the configuration of the Haxe compiler
 */
typedef HaxeConfig = {
	sourceDir:String,
	hxMain:String,
	cppOutDir:String,
	debugMode:Bool,
	othersOptions:Array<String>,
	errorReportingStyle:String,
}

/**
 * The SwitchConfig is used to store the configuration of the Nintendo Switch Linker.
 */
typedef SwitchConfig = {
	projectName:String,
	consoleIP:String,
}

/**
 * The main structure of the JSON file.
 */
typedef JsonStruct = {
	programVersion:String,
	haxeConfig:HaxeConfig,
	switchConfig:SwitchConfig,
	deleteTempFiles:Bool,
	extraLibs:Array<String>,
	projectDefines:Array<String>,
}

/**
 * The JsonFile class is used to parse the JSON file that contains the configuration of the project
 */
class JsonFile {
	/**
	 * Checks if the JSON file is valid
	 * @return Bool
	 */
	public static function checkJson():Bool {
		try {
			if (FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/haxeNXConfig.json")) {
				var jsonFile:JsonStruct = JsonFile.getJson();
				if (jsonFile == null) {
					SlushiUtils.printMsg("JSON file is invalid, please check it", ERROR);
					return false;
				}
			}
			return true;
		}
		catch (e) {
			SlushiUtils.printMsg("JSON file is invalid, please check it (" + e + ")", ERROR);
			return false;
		}
	}

	/**
	 * Returns the JSON file as a JsonStruct from the current directory
	 * @return JsonStruct
	 */
	public static function getJson():JsonStruct {
		try {
			if (FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/haxeNXConfig.json")) {
				var jsonContent:Dynamic = Json.parse(File.getContent(SlushiUtils.getPathFromCurrentTerminal() + "/haxeNXConfig.json"));

				var jsonStructure:JsonStruct = {
					programVersion: jsonContent.programVersion,
					haxeConfig: {
						sourceDir: jsonContent.haxeConfig.sourceDir,
						hxMain: jsonContent.haxeConfig.hxMain,
						cppOutDir: jsonContent.haxeConfig.cppOutDir,
						debugMode: jsonContent.haxeConfig.debugMode,
						othersOptions: jsonContent.haxeConfig.othersOptions,
						errorReportingStyle: jsonContent.haxeConfig.errorReportingStyle,
					},
					switchConfig: {
						projectName: jsonContent.switchConfig.projectName,
						consoleIP: jsonContent.switchConfig.consoleIP,
					},
					deleteTempFiles: jsonContent.deleteTempFiles,
					extraLibs: jsonContent.extraLibs,
					projectDefines: jsonContent.projectDefines,
				};
				return jsonStructure;
			}
		} catch (e) {
			SlushiUtils.printMsg("Error loading [haxeNXConfig.json]: " + e, ERROR);
		}
		return null;
	}

	/**
	 * Creates a new JSON file if it doesn't exist
	 */
	public static function createJson():Void {
		if (FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/haxeNXConfig.json")) {
			SlushiUtils.printMsg("[haxeNXConfig.json] already exists!", WARN);
			return;
		}

		SlushiUtils.printMsg("Creating [haxeNXConfig.json]...", PROCESSING);

		var jsonStructure:JsonStruct = {
			programVersion: Main.version,
			haxeConfig: {
				sourceDir: "source",
				hxMain: "Main",
				cppOutDir: "output",
				debugMode: false,
				othersOptions: [],
				errorReportingStyle: "pretty",
			},
			switchConfig: {
				projectName: "Project",
				consoleIP: "0.0.0.0",
			},
			deleteTempFiles: true,
			extraLibs: [],
			projectDefines: [],
		};

		try {
			File.saveContent(SlushiUtils.getPathFromCurrentTerminal() + "/haxeNXConfig.json", Json.stringify(jsonStructure, "\t"));
			SlushiUtils.printMsg("Created [haxeNXConfig.json]", SUCCESS);
		} catch (e) {
			SlushiUtils.printMsg("Error creating [haxeNXConfig.json]: " + e, ERROR);
		}
	}

	//////////////////////////////////////////////////////////////

	/**
	 * Returns the defines that are in the JSON file as a string for the Nintendo Switch linker
	 * @return String
	 */
	public static function parseJSONVars():String {
		var jsonFile:JsonStruct = JsonFile.getJson();
		if (jsonFile == null) {
			return "";
		}

		var defines:String = "";

		defines += "-D HAXENXCOMPILER_VERSION=\\\"" + Main.version + "\\\" ";
		defines += "-D HAXENXCOMPILER_JSON_SWITCH_PROJECTNAME=\\\"" + jsonFile.switchConfig.projectName + "\\\" ";

		var dateNow:Date = Date.now();
		var dateString = dateNow.getHours() + ":" + StringTools.lpad(dateNow.getMinutes() + "", "0", 2) + ":"
			+ StringTools.lpad(dateNow.getSeconds() + "", "0", 2) + "--" + StringTools.lpad(dateNow.getDate() + "", "0", 2) + "-"
			+ StringTools.lpad((dateNow.getMonth() + 1) + "", "0", 2) + "-" + dateNow.getFullYear();

		defines += "-D HAXENXCOMPILER_HAXE_APPROXIMATED_COMPILATION_DATE=\\\"" + dateString + "\\\" ";
		return defines;
	}


	//////////////////////////////////////////////////////////////

	/**
	 * Imports the JSON file from a Haxe library
	 * @param lib 
	 */
	public static function importJSON(lib:String):Void {
		var mainPath:String = "";
		var haxelibPath:String = Sys.getEnv("HAXEPATH") + "/lib";

		if (FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + "/.haxelib")) {
			mainPath = SlushiUtils.getPathFromCurrentTerminal() + "/.haxelib";
		} else {
			mainPath = haxelibPath;
		}

		if (!FileSystem.exists(mainPath + "/" + lib)) {
			SlushiUtils.printMsg("Lib [" + lib + "] not found", ERROR);
			return;
		}

		try {
			var hxuConfigPath:String = "";
			var currentFile:String = File.getContent(mainPath + "/" + lib + "/.current");
			if (currentFile == "git") {
				hxuConfigPath = mainPath + "/" + lib + "/git/haxeNXConfig.json";
			} else {
				hxuConfigPath = mainPath + "/" + lib + "/" + currentFile.replace(".", ",") + "/haxeNXConfig.json";
			}

			if (!FileSystem.exists(hxuConfigPath)) {
				SlushiUtils.printMsg("haxeNXConfig.json not found in [" + lib + "]", WARN);
				return;
			}

			File.copy(hxuConfigPath, SlushiUtils.getPathFromCurrentTerminal() + "/haxeNXConfig.json");
		}
		catch (e) {
			SlushiUtils.printMsg("Error importing [haxeNXConfig.json]: " + e, ERROR);
			return;
		}

		SlushiUtils.printMsg("[haxeNXConfig.json] imported from [" + lib + "]", SUCCESS);
	}
}
