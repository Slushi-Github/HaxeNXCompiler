// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


package src.compilers;

import utils.AssetsManager;
import src.SlushiUtils;
import src.compilers.NXLinker;
import src.compilers.HaxeCompiler;
import src.utils.LibsManager;
import src.JsonFile;
import src.utils.DevKitProUtils;
import src.Main;

using StringTools;

/**
 * The main compiler, it will start the compilation of the project
 * in Haxe and Wii U.
 * 
 * Author: Slushi.
 */
class MainCompiler {
	public static var libs:Array<HxNXLibStruct> = [];

	/**
	 * Starts the compilation of the project.
	 */
	public static function start(arg2:String, arg3:String):Void {
		var jsonVersion:String = JsonFile.getJson().programVersion;
		var forced:Bool = jsonVersion.endsWith(":forced");
		var versionStr = forced ? jsonVersion.split(":")[0] : jsonVersion;

		var operatorStr:String = "";
		var versionValue:String = versionStr;

		if (versionStr.startsWith(">=")) {
			operatorStr = ">=";
			versionValue = versionStr.substr(2);
		} else if (versionStr.startsWith(">")) {
			operatorStr = ">";
			versionValue = versionStr.substr(1);
		} else if (versionStr.startsWith("<=")) {
			operatorStr = "<=";
			versionValue = versionStr.substr(2);
		} else if (versionStr.startsWith("<")) {
			operatorStr = "<";
			versionValue = versionStr.substr(1);
		}

		var parsedJsonVersion = SlushiUtils.parseVersion(versionValue);
		var currentVersion = SlushiUtils.parseVersion(Main.version);

		var versionMismatch:Bool = false;
		var shouldStop:Bool = false;

		if (operatorStr == ">=") {
			if (currentVersion < parsedJsonVersion) {
				versionMismatch = true;
				shouldStop = true; // Stop if current version is less than required
			}
			// If currentVersion >= parsedJsonVersion, continue
		} else if (operatorStr == ">") {
			if (currentVersion <= parsedJsonVersion) {
				versionMismatch = true;
				shouldStop = true; // Stop if current version is less or equal
			}
		} else if (operatorStr == "<=") {
			if (currentVersion > parsedJsonVersion) {
				versionMismatch = true;
				shouldStop = true; // Stop if current version is greater than required
			}
			// If currentVersion <= parsedJsonVersion, continue
		} else if (operatorStr == "<") {
			if (currentVersion >= parsedJsonVersion) {
				versionMismatch = true;
				shouldStop = true; // Stop if current version is greater or equal
			}
		} else {
			if (currentVersion < parsedJsonVersion) {
				SlushiUtils.printMsg("The current version of HaxeNXCompiler is older than the one in the JSON file, consider updating it.", WARN);
				if (forced) {
					versionMismatch = true;
					shouldStop = true; // Stop if forced
				}
			} else if (currentVersion > parsedJsonVersion) {
				SlushiUtils.printMsg("The current version of HaxeNXCompiler is newer than the one in the JSON file, consider checking the JSON file.", WARN);
				if (forced) {
					versionMismatch = true;
					shouldStop = true; // Stop if forced
				}
			}
		}

		if (shouldStop) {
			SlushiUtils.printMsg("Cannot continue: The JSON requires a specific version of HaxeNXCompiler: " + jsonVersion, ERROR);
			return;
		}

		// Check and get required libs
		libs = LibsManager.getRequiredLibs();

		if (arg2.toLowerCase() == "--debug") {
			HaxeCompiler.forceDebugMode = true;
		}
		else if (arg2.toLowerCase() == "--clean") {
			SlushiUtils.cleanBuild();
		}

		// First compile Haxe part, copy the assets files and then compile Nintendo Switch part
		HaxeCompiler.init();
		SlushiUtils.printMsg("----------------------", NONE);
		AssetsManager.searchAndGetAssets();
		SlushiUtils.printMsg("----------------------\n", NONE);
		NXLinker.init();
	}
}
