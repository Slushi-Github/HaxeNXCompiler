// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.
package source.managers;

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
 * Represents a Haxe library with its name and optional version
 */
typedef HaxeLibInfo = {
	name:String,
	?version:String
}

/**
 * Manages the libraries of the project and its dependencies
 * 
 * Author: Slushi, Claude
 */
class LibsManager {
	public static var instance:LibsManager = null;

	/**
	 * The name of the JSON file
	 */
	private static final jsonName:String = "HxNX_Meta.json";

	public var libs:Array<HxNXLibStruct> = [];

	private var importedLibs:Map<String, Bool> = new Map();
	private var haxelibPath:String = "";
	private var mainPath:String = "";

	// Store all discovered Haxe libraries (including from dependencies)
	private var allHaxeLibs:Map<String, HaxeLibInfo> = new Map();

	public function new() {
		instance = this;

		// Setup paths
		haxelibPath = Sys.getEnv("HAXEPATH") + "/lib";
		if (FileSystem.exists(CommandLineUtils.getPathFromCurrentTerminal() + "/.haxelib")) {
			mainPath = CommandLineUtils.getPathFromCurrentTerminal() + "/.haxelib";
		} else {
			mainPath = haxelibPath;
		}

		var requiredMainLibs:Array<HaxeLib> = ProjectFile.instance.getActiveHaxeLibs();

		if (requiredMainLibs.length == 0) {
			Logger.log("No extra libs found for this project, skipping.", INFO);
			return;
		}

		// Logger.log("Searching for libraries and dependencies...", PROCESSING);

		// First, add the main project libraries
		for (lib in requiredMainLibs) {

			if (lib.name == "hx_libnx") {
				Logger.log("The \"hx_libnx\" library is already imported by default, skipping.", INFO);
				continue;
			}

			var libKey = lib.name + (lib.version != null ? ":" + lib.version : "");
			if (!allHaxeLibs.exists(libKey)) {
				allHaxeLibs.set(libKey, {name: lib.name, version: lib.version});
			}
		}

		// Import all libraries recursively
		for (lib in requiredMainLibs) {
			importLibrary(lib.name, lib.version);
		}

		// Logger.log('Found ${libs.length} library(ies) with HxNX metadata.', SUCCESS);
		// Logger.log('Total Haxe libraries (including dependencies): ${Lambda.count(allHaxeLibs)}', INFO);
	}

	/**
	 * Imports a library and all its dependencies recursively
	 * @param libName The name of the library
	 * @param version Optional specific version
	 */
	private function importLibrary(libName:String, ?version:String):Void {
		// Check if already imported
		var libKey = libName + (version != null ? ":" + version : "");
		if (importedLibs.exists(libKey)) {
			return; // Already imported, skip
		}

		// Mark as imported to avoid circular dependencies
		importedLibs.set(libKey, true);

		var libFolder = mainPath + "/" + libName;
		if (!FileSystem.exists(libFolder)) {
			Logger.exitBecauseError('Could not find Haxe library: ${libName}\nPlease install it with: "haxelib install ${libName}" if the library exists in "https://lib.haxe.org/", if not, use "haxelib git ${libName} GIT_URL" instead.');
		}

		// Determine version folder
		var versionFolder = "";
		var actualVersion = version;

		if (version != null) {
			versionFolder = "/" + version.replace(".", ",");
			actualVersion = version;
		} else if (FileSystem.exists(libFolder + "/.current")) {
			var currentContent = File.getContent(libFolder + "/.current").trim();
			if (currentContent == "git") {
				versionFolder = "/git";
				actualVersion = "git";
			} else {
				versionFolder = "/" + currentContent.replace(".", ",");
				actualVersion = currentContent;
			}
		}

		// Build meta path
		var metaPath = libFolder + versionFolder + "/" + jsonName;

		if (!FileSystem.exists(metaPath)) {
			Logger.log('Meta file [${jsonName}] not found for lib [${libName}], importing only for Haxe.', WARNING);
			libs.push({
				libJSONData: {
					libVersion: actualVersion != null ? actualVersion : "unknown",
					haxeLibs: [],
					switchLibs: [],
					hxDefines: [],
					mainDefines: [],
					cDefines: [],
					cppDefines: []
				},
				hxLibName: libName,
				hxLibVersion: actualVersion
			});
			return;
		}

		// Load and parse JSON
		try {
			var jsonContent = File.getContent(metaPath);
			var jsonData:HxNXLibJSONStruct = Json.parse(jsonContent);

			// Add library to list
			libs.push({
				libJSONData: jsonData,
				hxLibName: libName,
				hxLibVersion: actualVersion != null ? actualVersion : jsonData.libVersion
			});

			// Logger.log('Imported library: ${libName}${actualVersion != null ? ":" + actualVersion : ""} with HxNX metadata', INFO);

			// Recursively import dependencies
			if (jsonData.haxeLibs != null && jsonData.haxeLibs.length > 0) {
				for (depLib in jsonData.haxeLibs) {
					// Parse library name and version from string
					var depName = depLib;
					var depVersion:String = null;

					if (depLib.contains(":")) {
						var parts = depLib.split(":");
						depName = parts[0];
						depVersion = parts[1];
					}

					// Add to all haxe libs map
					var depLibKey = depName + (depVersion != null ? ":" + depVersion : "");
					if (!allHaxeLibs.exists(depLibKey)) {
						allHaxeLibs.set(depLibKey, {name: depName, version: depVersion});
						// Logger.log('Found dependency: ${depName}${depVersion != null ? ":" + depVersion : ""}', INFO);
					}

					// Recursively import dependency
					importLibrary(depName, depVersion);
				}
			}
		} catch (e) {
			Logger.exitBecauseError('Error loading meta file for [${libName}]: ${e}');
		}
	}

	/**
	 * Gets all Haxe libraries (including from dependencies)
	 * @return Array of HaxeLibInfo
	 */
	public function getAllHaxeLibs():Array<HaxeLibInfo> {
		var result:Array<HaxeLibInfo> = [];
		for (lib in allHaxeLibs) {
			result.push(lib);
		}
		return result;
	}

	/**
	 * Generates the haxelib string for Haxe compiler (one per line)
	 * Includes ALL libraries found (main + dependencies)
	 * Format: "-lib name" or "-lib name:version"
	 */
	public function generateAllHaxeLibsString():String {
		var lines:Array<String> = [];

		for (lib in allHaxeLibs) {
			var line = "-lib " + lib.name;
			if (lib.version != null) {
				line += ":" + lib.version;
			}
			lines.push(line);
		}

		return lines.join("\n\t");
	}

	/**
	 * Generates haxe defines for each library with its version
	 * Format: -D libraryname=version or -D libraryname if no version
	 */
	public function generateAllHaxeLibDefsString():String {
		var lines:Array<String> = [];

		for (lib in allHaxeLibs) {
			if (lib.version != null && lib.version != "git") {
				lines.push('-D ${lib.name}="${lib.version}"');
			} else {
				lines.push('-D ${lib.name}="unknown"');
			}
		}

		return lines.join("\n\t");
	}

	/**
	 * Gets all switch libraries from all imported libraries
	 */
	public function getAllSwitchLibs():Array<String> {
		var allLibs:Array<String> = [];
		var libSet = new Map<String, Bool>();

		for (lib in libs) {
			if (lib.libJSONData.switchLibs != null) {
				for (switchLib in lib.libJSONData.switchLibs) {
					if (!libSet.exists(switchLib)) {
						allLibs.push(switchLib);
						libSet.set(switchLib, true);
					}
				}
			}
		}

		return allLibs;
	}

	/**
	 * Gets all main defines from all imported libraries
	 */
	public function getAllMainDefines():Array<String> {
		var allDefines:Array<String> = [];
		var defineSet = new Map<String, Bool>();

		for (lib in libs) {
			if (lib.libJSONData.mainDefines != null) {
				for (define in lib.libJSONData.mainDefines) {
					if (!defineSet.exists(define)) {
						allDefines.push(define);
						defineSet.set(define, true);
					}
				}
			}
		}

		return allDefines;
	}

	/**
	 * Gets all haxe defines from all imported libraries
	 */
	public function getAllHxDefines():Array<String> {
		var allDefines:Array<String> = [];
		var defineSet = new Map<String, Bool>();

		for (lib in libs) {
			if (lib.libJSONData.hxDefines != null) {
				for (define in lib.libJSONData.hxDefines) {
					if (!defineSet.exists(define)) {
						allDefines.push(define);
						defineSet.set(define, true);
					}
				}
			}
		}

		return allDefines;
	}

	/**
	 * Gets all C defines from all imported libraries
	 */
	public function getAllCDefines():Array<String> {
		var allDefines:Array<String> = [];
		var defineSet = new Map<String, Bool>();

		for (lib in libs) {
			if (lib.libJSONData.cDefines != null) {
				for (define in lib.libJSONData.cDefines) {
					if (!defineSet.exists(define)) {
						allDefines.push(define);
						defineSet.set(define, true);
					}
				}
			}
		}

		return allDefines;
	}

	/**
	 * Gets all C++ defines from all imported libraries
	 */
	public function getAllCppDefines():Array<String> {
		var allDefines:Array<String> = [];
		var defineSet = new Map<String, Bool>();

		for (lib in libs) {
			if (lib.libJSONData.cppDefines != null) {
				for (define in lib.libJSONData.cppDefines) {
					if (!defineSet.exists(define)) {
						allDefines.push(define);
						defineSet.set(define, true);
					}
				}
			}
		}

		return allDefines;
	}

	/**
	 * Generates the switch libs string for MakeFile
	 * Format: "-lname1 -lname2"
	 */
	public function generateSwitchLibsString():String {
		var libs = getAllSwitchLibs();
		if (libs.length == 0)
			return "";

		var result = "";
		for (lib in libs) {
			result += "-l" + lib + " ";
		}

		return result.trim();
	}

	/**
	 * Generates the C defines string for MakeFile
	 * Format: "-DDEFINE1 -DDEFINE2"
	 */
	public function generateCDefinesString():String {
		var defines = getAllCDefines();
		if (defines.length == 0)
			return "";

		var result = "";
		for (define in defines) {
			result += define + " ";
		}

		return result.trim();
	}

	/**
	 * Generates the C++ defines string for MakeFile
	 * Format: "-DDEFINE1 -DDEFINE2"
	 */
	public function generateCppDefinesString():String {
		var defines = getAllCppDefines();
		if (defines.length == 0)
			return "";

		var result = "";
		for (define in defines) {
			result += define + " ";
		}

		return result.trim();
	}

	/**
	 * Generates the Haxe defines string for Haxe compiler (one per line)
	 * Format: "-D DEFINE1\n-D DEFINE2"
	 */
	public function generateHxDefinesString():String {
		var defines = getAllHxDefines();
		if (defines.length == 0)
			return "";

		var lines:Array<String> = [];
		for (define in defines) {
			lines.push(define);
		}

		return lines.join("\n\t");
	}
}