// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


package src.utils;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import src.JsonFile;
import src.compilers.MainCompiler;

using StringTools;

/**
 * The HxNXLibJSONStruct is used to store the JSON data of a HxNX library.
 */
typedef HxNXLibJSONStruct = {
	libVersion:String,
	// Haxe things
	haxeLibs:Array<String>,
	// Nintendo Switch things
	switchLibs:Array<String>,
	// Other things
	mainDefines:Array<String>,
	// Haxe things
	hxDefines:Array<String>,
	// MakeFile things
	cDefines:Array<String>,
	cppDefines:Array<String>
}

/**
 * The HxNXLibStruct is used to store the data of a HxNX library.
 * It contains the JSON data of the library and the name of the Haxe library.
 */
typedef HxNXLibStruct = {
    libJSONData:HxNXLibJSONStruct,
    hxLibName:String,
	hxLibVersion:String
}

/**
 * The LibsManager class is used to manage the libs of the project, it will
 * parse check the libs in the JSON file and return the required libs for the project.
 *
 * This was much easier than the first version of the HxCompileU library manager, now 
 * there are no longer only a few libraries allowed per compiler version, they can
 * now be as many as the user needs.
 * In addition to searching for each Haxe library, if a library 
 * requires additional Haxe libraries, the compiler will search for them and if 
 * they exist, it will import the necessary data (like more Haxe libraries 
 * or the C++ libraries for the Nintendo Switch).
 *
 * Author: Slushi.
 */
class LibsManager {
	private static final jsonName:String = "HxNX_Meta.json";

	static var mainJsonFile:JsonStruct = JsonFile.getJson();

	public static function getRequiredLibs():Array<HxNXLibStruct> {
		var libs:Array<HxNXLibStruct> = [];
		var importedLibs = new Map<String, Bool>();
		if (mainJsonFile.extraLibs.length == 0) {
			SlushiUtils.printMsg("No extra libs found in the main JSON file, skipping.", INFO);
			return libs;
		}

		var requiredMainLibs:Array<String> = mainJsonFile.extraLibs;

		// Why import hx_hx_libnx again? It's already hardcoded in the HXML template heh
		if (requiredMainLibs.contains("hx_libnx")) {
			SlushiUtils.printMsg("The \"hx_libnx\" library is already imported by HaxeNXCompiler, it will not be imported again.", WARN);
			requiredMainLibs.remove("hx_libnx");
		}

		var mainPath:String = "";
		var haxelibPath:String = Sys.getEnv("HAXEPATH") + "/lib";

		if (FileSystem.exists(SlushiUtils.getPathFromCurrentTerminal() + ".haxelib")) {
			mainPath = SlushiUtils.getPathFromCurrentTerminal() + ".haxelib";
		} else {
			mainPath = haxelibPath;
		}

		function processLib(libName:String, libVersion:String = null) {
			// if (importedLibs.exists(libName)) {
			// 	SlushiUtils.printMsg("Lib [" + libName + "] already imported.", WARN);
			// 	return;
			// }
			importedLibs.set(libName, true);

			var libFolder = mainPath + "/" + libName;
			if (!FileSystem.exists(libFolder)) {
				SlushiUtils.printMsg("Required Haxe lib [" + libName + "] not found.", WARN);
				return;
			}
			var versionFolder = "";
			if (libVersion != null) {
				versionFolder = libVersion.replace(".", ",");
			} else if (FileSystem.exists(libFolder + "/.current")) {
				var currentVersion = File.getContent(libFolder + "/.current").trim();
				versionFolder = currentVersion.replace(".", ",");
			}
			var metaPath = "";
			if (FileSystem.exists(libFolder + "/.current") && File.getContent(libFolder + "/.current").trim() == "git") {
				metaPath = libFolder + "/git/" + jsonName;
			} else {
				metaPath = libFolder + "/" + versionFolder + "/" + jsonName;
			}
			if (!FileSystem.exists(metaPath)) {
				SlushiUtils.printMsg("Meta file [" + metaPath + "] not found for lib [" + libName + "], importing only for Haxe.", WARN);
				libs.push({
					libJSONData: {
						libVersion: "unknown",
						haxeLibs: [],
						switchLibs: [],
						hxDefines: [],
						mainDefines: [],
						cDefines: [],
						cppDefines: []
					},
					hxLibName: libName,
					hxLibVersion: "0.0.0"
				});
				return;
			}
			try {
				var fileContent = File.getContent(metaPath);
				var jsonContent:Dynamic = Json.parse(fileContent);

				libs.push({
					libJSONData: {
						libVersion: jsonContent.libVersion ?? "0.0.0",
						haxeLibs: jsonContent.haxeLibs ?? new Array<String>(),
						switchLibs: jsonContent.switchLibs ?? new Array<String>(),
						hxDefines: jsonContent.hxDefines ?? new Array<String>(),
						mainDefines: jsonContent.mainDefines ?? new Array<String>(),
						cDefines: jsonContent.cDefines ?? new Array<String>(),
						cppDefines: jsonContent.cppDefines ?? new Array<String>(),
					},
					hxLibName: libName,
					hxLibVersion: jsonContent.libVersion ?? "0.0.0"
				});

				// Recursively process extra haxeLibs
				var jsonExtraLibs:Array<String> = jsonContent.haxeLibs ?? new Array<String>();
				for (extraLib in jsonExtraLibs) {
					var extraLibName = extraLib;
					var extraLibVersion:String = null;
					if (extraLib.indexOf(":") != -1) {
						var parts = extraLib.split(":");
						extraLibName = parts[0];
						extraLibVersion = parts[1];
					}
					processLib(extraLibName, extraLibVersion);
				}
			} catch (e) {
				SlushiUtils.printMsg("Error loading [" + metaPath + "]: " + e, ERROR);
				return;
			}
		}

		for (libEntry in requiredMainLibs) {
			var libName = libEntry;
			var libVersion:String = null;
			if (libEntry.indexOf(":") != -1) {
				var parts = libEntry.split(":");
				libName = parts[0];
				libVersion = parts[1];
			}
			processLib(libName, libVersion);
		}
		return libs;
	}

	public static function parseHXLibs():Array<String> {
		var libs:Array<String> = [];

		for (i in 0...MainCompiler.libs.length) {
			libs.push("-lib " + MainCompiler.libs[i].hxLibName ?? "");

			for (lib in MainCompiler.libs[i].libJSONData.haxeLibs ?? new Array<String>()) {
				if (lib == null || lib == "") {
					continue;
				}
				libs.push("-lib " + lib);
			}
		}

		return libs;
	}

	public static function parseCPPLibs():Array<String> {
		var libs:Array<String> = [];

		for (i in 0...MainCompiler.libs.length) {
			if (MainCompiler.libs[i].libJSONData.switchLibs?.length ?? 0 <= 0 ) {
				continue;
			}

			for (lib in MainCompiler.libs[i].libJSONData.switchLibs ?? new Array<String>()) {
				if (lib == null || lib == "") {
					continue;
				}
				libs.push("-l" + lib);
			}
		}

		return libs;
	}
}