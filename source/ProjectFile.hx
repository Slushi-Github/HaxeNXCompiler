// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source;

import haxe.io.Path;
import haxe.xml.Access;

// Typedefs for configuration
typedef SourcePath = {
	path:String
}

typedef HaxeLib = {
	name:String,
	?version:String,
	?condition:String // if="DEFINE"
}

typedef SwitchLib = {
	name:String
}

typedef Define = {
	name:String,
	?value:String,
	?condition:String
}

typedef Flag = {
	name:String,
	?value:String,
	?condition:String
}

typedef Section = {
	condition:String, // if="DEFINE"
	elements:Array<SectionElement>
}

typedef SectionElement = {
	type:SectionElementType,
	value:String,
	?condition:String
}

enum SectionElementType {
	Echo;
	Error;
	Define(name:String, ?value:String);
}

typedef SwitchMeta = {
	appTitle:String,
	appVersion:String,
	appAuthor:String
}

typedef ProjectConfig = {
	// Paths
	sourcePath:String,
	haxeMain:String,
	cppOutput:String,
	errorReportingStyle:String,

	// Switch config
	switchProjectName:String,
	switchConsoleIP:String,
	switchMeta:SwitchMeta,

	// Libraries
	haxeLibs:Array<HaxeLib>,
	switchLibs:Array<SwitchLib>,

	// Defines and flags
	defines:Array<Define>,
	haxeDefs:Array<Define>,
	cDefs:Array<Define>,
	cppDefs:Array<Define>,

	// Flags
	haxeFlags:Array<Flag>,
	cFlags:Array<Flag>,
	cppFlags:Array<Flag>,

	// Sections
	sections:Array<Section>,

	// Config
	makeFileMaxJobs:Int,
	sendAfterCompile:Bool,
	deleteTempFiles:Bool,
	haxeDebug:Bool,

	// Compiler version requirement
	hxnxcompilerVersion:String,

	// Active defines (for condition evaluation)
	activeDefines:Map<String, String>
}

/**
 * Represents an XML-based project, similar to Lime/OpenFL
 * 
 * Author: Slushi, Claude
 */
class ProjectFile {
	public static var instance:ProjectFile = null;

	public var config:ProjectConfig;

	private var xmlPath:String;

	public static final projectFileName = "HxNXProject.xml";

	public function new() {
		xmlPath = projectFileName;
		config = {
			sourcePath: "",
			haxeMain: "Main",
			cppOutput: "output",
			errorReportingStyle: "pretty",
			switchProjectName: "Project",
			switchConsoleIP: "0.0.0.0",
			switchMeta: {
				appTitle: "Project",
				appVersion: "1.0.0",
				appAuthor: "None"
			},
			haxeLibs: [],
			switchLibs: [],
			defines: [],
			haxeDefs: [],
			cDefs: [],
			cppDefs: [],
			haxeFlags: [],
			cFlags: [],
			cppFlags: [],
			sections: [],
			makeFileMaxJobs: 2,
			sendAfterCompile: false,
			deleteTempFiles: false,
			haxeDebug: false,
			hxnxcompilerVersion: Main.VERSION,
			activeDefines: new Map<String, String>()
		};
	}

	/**
	 * Loads the project XML file
	 */
	public function load():Void {
		var fullPath = CommandLineUtils.getPathFromCurrentTerminal() + "/" + xmlPath;

		if (!FileSystem.exists(fullPath)) {
			Logger.exitBecauseError("[" + xmlPath + "] not found!");
		}

		try {
			var content = File.getContent(fullPath);
			var xml = Xml.parse(content);
			var access = new Access(xml.firstElement());

			parseXML(access);

			// Validate required fields
			if (!validateRequiredFields()) {
				Logger.exitBecauseError("Missing required fields, cannot continue.");
			}

			// Validate compiler version
			if (!validateCompilerVersion()) {
				Logger.exitBecauseError("Compiler version requirement not met, cannot continue.");
			}

			processSections();

			Logger.log("Loaded [" + xmlPath + "]", SUCCESS);
		} catch (e) {
			Logger.exitBecauseError("Error loading [" + xmlPath + "]: " + e);
		}
	}

	/**
	 * Validates that required fields are present and valid
	 */
	private function validateRequiredFields():Bool {
		var errors:Array<String> = [];

		// Validate source path
		if (config.sourcePath == null || config.sourcePath == "") {
			errors.push("Missing required field: <source path=\"...\"/>");
		}

		// Validate haxe main
		if (config.haxeMain == null || config.haxeMain == "") {
			errors.push("Missing required field: <haxemain name=\"...\"/>");
		}

		// Validate cpp output
		if (config.cppOutput == null || config.cppOutput == "") {
			errors.push("Missing required field: <cppOutput path=\"...\"/>");
		}

		// Validate switch project name
		if (config.switchProjectName == null || config.switchProjectName == "") {
			errors.push("Missing required field: <switchproject name=\"...\" />. Project name cannot be empty.");
		}

		// If there are errors, show them and return false
		if (errors.length > 0) {
			Logger.log("Project validation failed:", ERROR);
			for (error in errors) {
				Logger.log(" - " + error, NONE);
			}
		}

		return true;
	}

	/**
	 * Validates the compiler version requirement
	 * Supports: "3.0.0", ">3.0.0", ">=3.0.0", "<3.0.0", "<=3.0.0"
	 */
	private function validateCompilerVersion():Bool {
		if (config.hxnxcompilerVersion == null || config.hxnxcompilerVersion == "") {
			return true; // No version requirement
		}

		var requirement = config.hxnxcompilerVersion.trim();
		var currentVersion = Main.VERSION;

		// Parse operatorStr and version
		var operatorStr = "=";
		var requiredVersion = requirement;

		if (requirement.startsWith(">=")) {
			operatorStr = ">=";
			requiredVersion = requirement.substr(2).trim();
		} else if (requirement.startsWith("<=")) {
			operatorStr = "<=";
			requiredVersion = requirement.substr(2).trim();
		} else if (requirement.startsWith(">")) {
			operatorStr = ">";
			requiredVersion = requirement.substr(1).trim();
		} else if (requirement.startsWith("<")) {
			operatorStr = "<";
			requiredVersion = requirement.substr(1).trim();
		}

		// Compare versions
		var comparison = compareVersions(currentVersion, requiredVersion);
		var isValid = false;

		switch (operatorStr) {
			case "=":
				isValid = comparison == 0;
			case ">":
				isValid = comparison > 0;
			case ">=":
				isValid = comparison >= 0;
			case "<":
				isValid = comparison < 0;
			case "<=":
				isValid = comparison <= 0;
		}

		if (!isValid) {
			Logger.log("Compiler version mismatch:", ERROR);
			Logger.log('  Required: ${operatorStr}${requiredVersion}', ERROR);
			Logger.log('  Current: ${currentVersion}', ERROR);
			return false;
		}

		return true;
	}

	/**
	 * Compares two version strings (e.g., "3.0.0" vs "2.5.1")
	 * Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
	 */
	private function compareVersions(v1:String, v2:String):Int {
		var parts1 = v1.split(".").map(Std.parseInt);
		var parts2 = v2.split(".").map(Std.parseInt);

		var maxLength = Std.int(Math.max(parts1.length, parts2.length));

		for (i in 0...maxLength) {
			var p1 = i < parts1.length ? parts1[i] : 0;
			var p2 = i < parts2.length ? parts2[i] : 0;

			if (p1 == null)
				p1 = 0;
			if (p2 == null)
				p2 = 0;

			if (p1 > p2)
				return 1;
			if (p1 < p2)
				return -1;
		}

		return 0;
	}

	/**
	 * Parses the XML and fills the configuration
	 */
	private function parseXML(xml:Access):Void {
		// Source paths
		if (xml.hasNode.source) {
			config.sourcePath = xml.node.source.att.path;
		}

		// Haxe main
		if (xml.hasNode.haxemain) {
			config.haxeMain = xml.node.haxemain.att.name;
		}

		// Error reporting style
		if (xml.hasNode.haxerrorreportingstyle) {
			config.errorReportingStyle = xml.node.haxerrorreportingstyle.att.type;
		}

		// C++ Output
		if (xml.hasNode.cppoutput) {
			config.cppOutput = xml.node.cppoutput.att.path;
		}

		// Switch project
		if (xml.hasNode.switchproject) {
			var node = xml.node.switchproject;
			if (node.has.name)
				config.switchProjectName = node.att.name;
			if (node.has.consoleip)
				config.switchConsoleIP = node.att.consoleip;
		}

		// Switch meta
		if (xml.hasNode.switchmeta) {
			var node = xml.node.switchmeta;
			if (node.has.apptitle)
				config.switchMeta.appTitle = node.att.apptitle;
			if (node.has.appversion)
				config.switchMeta.appVersion = node.att.appversion;
			if (node.has.appauthor)
				config.switchMeta.appAuthor = node.att.appauthor;
		}

		// Defines (activated immediately)
		for (define in xml.nodes.define) {
			var name = define.att.name;
			var value = define.has.value ? define.att.value : "1";
			config.activeDefines.set(name, value);
			config.defines.push({name: name, value: value});
		}

		// Haxe libs
		for (lib in xml.nodes.haxelib) {
			var libData:HaxeLib = {
				name: lib.att.name,
				version: lib.has.version ? lib.att.version : null,
				condition: lib.has.resolve("if") ? lib.att.resolve("if") : null
			};
			config.haxeLibs.push(libData);
		}

		// Switch libs
		for (lib in xml.nodes.switchlib) {
			config.switchLibs.push({name: lib.att.name});
		}

		// Haxe defs
		for (def in xml.nodes.haxedef) {
			config.haxeDefs.push({
				name: def.att.name,
				value: def.has.value ? def.att.value : null,
				condition: def.has.resolve("if") ? def.att.resolve("if") : null
			});
		}

		// C defs
		for (def in xml.nodes.cdef) {
			config.cDefs.push({
				name: def.att.name,
				value: def.has.value ? def.att.value : null,
				condition: def.has.resolve("if") ? def.att.resolve("if") : null
			});
		}

		// C++ defs
		for (def in xml.nodes.cppdef) {
			config.cppDefs.push({
				name: def.att.name,
				value: def.has.value ? def.att.value : null,
				condition: def.has.resolve("if") ? def.att.resolve("if") : null
			});
		}

		// Haxe flags
		for (flag in xml.nodes.haxeflag) {
			config.haxeFlags.push({
				name: flag.att.name,
				value: flag.has.value ? flag.att.value : null,
				condition: flag.has.resolve("if") ? flag.att.resolve("if") : null
			});
		}

		// C flags
		for (flag in xml.nodes.cflag) {
			config.cFlags.push({
				name: flag.att.name,
				value: flag.has.value ? flag.att.value : null,
				condition: flag.has.resolve("if") ? flag.att.resolve("if") : null
			});
		}

		// C++ flags
		for (flag in xml.nodes.cppflag) {
			config.cppFlags.push({
				name: flag.att.name,
				value: flag.has.value ? flag.att.value : null,
				condition: flag.has.resolve("if") ? flag.att.resolve("if") : null
			});
		}

		// Sections
		for (section in xml.nodes.section) {
			if (!section.has.resolve("if"))
				continue;

			var sectionData:Section = {
				condition: section.att.resolve("if"),
				elements: []
			};

			// Echo
			for (echo in section.nodes.echo) {
				sectionData.elements.push({
					type: Echo,
					value: echo.att.value
				});
			}

			// Error
			for (error in section.nodes.error) {
				sectionData.elements.push({
					type: Error,
					value: error.att.value,
					condition: error.has.resolve("if") ? error.att.resolve("if") : null
				});
			}

			config.sections.push(sectionData);
		}

		// MakeFile jobs
		if (xml.hasNode.makefilejobs) {
			config.makeFileMaxJobs = Std.parseInt(xml.node.makefilejobs.att.value);
		}

		// Send after compile
		if (xml.hasNode.sendaftercompile) {
			config.sendAfterCompile = xml.node.sendaftercompile.att.value.toLowerCase() == "true";
		}

		// Delete temporal files
		if (xml.hasNode.deletetemporalfiles) {
			config.deleteTempFiles = xml.node.deletetemporalfiles.att.value.toLowerCase() == "true";
		}

		// Delete temporal files
		if (xml.hasNode.haxedebug) {
			config.haxeDebug = xml.node.haxedebug.att.value.toLowerCase() == "true";
		}

		// HxNXCompiler version requirement
		if (xml.hasNode.hxnxcompiler) {
			if (xml.node.hxnxcompiler.has.version) {
				config.hxnxcompilerVersion = xml.node.hxnxcompiler.att.version ?? Main.VERSION;
			}
		}
	}

	/**
	 * Processes conditional sections
	 */
	private function processSections():Void {
		for (section in config.sections) {
			if (!checkCondition(section.condition))
				continue;

			for (element in section.elements) {
				// Check element condition
				if (element.condition != null && !checkCondition(element.condition)) {
					continue;
				}

				switch (element.type) {
					case Echo:
						Logger.log(element.value, INFO);
					case Error:
						Logger.exitBecauseError("Project Error: " + element.value);
					case Define(name, value):
						config.activeDefines.set(name, value != null ? value : "1");
				}
			}
		}
	}

	/**
	 * Checks if a condition is active
	 * Supports: if="DEFINE", if="!DEFINE"
	 */
	private function checkCondition(condition:String):Bool {
		if (condition == null || condition == "")
			return true;

		var negate = condition.startsWith("!");
		var defineName = negate ? condition.substr(1) : condition;

		var exists = config.activeDefines.exists(defineName);
		return negate ? !exists : exists;
	}

	/**
	 * Gets the haxelibs that should be used (filtering by conditions)
	 */
	public function getActiveHaxeLibs():Array<HaxeLib> {
		return config.haxeLibs.filter(lib -> {
			return lib.condition == null || checkCondition(lib.condition);
		});
	}

	/**
	 * Gets the active haxe defines (filtering by conditions)
	 */
	public function getActiveHaxeDefs():Array<Define> {
		return config.haxeDefs.filter(def -> {
			return def.condition == null || checkCondition(def.condition);
		});
	}

	/**
	 * Gets the active haxe flags (filtering by conditions)
	 */
	public function getActiveHaxeFlags():Array<Flag> {
		return config.haxeFlags.filter(flag -> {
			return flag.condition == null || checkCondition(flag.condition);
		});
	}

	/**
	 * Gets the active C defines (filtering by conditions)
	 */
	public function getActiveCDefs():Array<Define> {
		return config.cDefs.filter(def -> {
			return def.condition == null || checkCondition(def.condition);
		});
	}

	/**
	 * Gets the active C++ defines (filtering by conditions)
	 */
	public function getActiveCppDefs():Array<Define> {
		return config.cppDefs.filter(def -> {
			return def.condition == null || checkCondition(def.condition);
		});
	}

	/**
	 * Gets the active C flags (filtering by conditions)
	 */
	public function getActiveCFlags():Array<Flag> {
		return config.cFlags.filter(flag -> {
			return flag.condition == null || checkCondition(flag.condition);
		});
	}

	/**
	 * Gets the active C++ flags (filtering by conditions)
	 */
	public function getActiveCppFlags():Array<Flag> {
		return config.cppFlags.filter(flag -> {
			return flag.condition == null || checkCondition(flag.condition);
		});
	}

	/**
	 * Generates the defines string for the Nintendo Switch linker (C defines)
	 */
	public function generateLinkerCDefines():String {
		var defines = "";

		defines += "-DHAXENXCOMPILER_VERSION=\\\"" + Main.VERSION + "\\\" ";
		defines += "-DHAXENXCOMPILER_SWITCH_PROJECTNAME=\\\"" + config.switchProjectName + "\\\" ";

		var dateNow = Date.now();
		var dateString = dateNow.getHours() + ":" + StringTools.lpad(dateNow.getMinutes() + "", "0", 2) + ":"
			+ StringTools.lpad(dateNow.getSeconds() + "", "0", 2) + "--" + StringTools.lpad(dateNow.getDate() + "", "0", 2) + "-"
			+ StringTools.lpad((dateNow.getMonth() + 1) + "", "0", 2) + "-" + dateNow.getFullYear();

		defines += "-DHAXENXCOMPILER_HAXE_APPROXIMATED_COMPILATION_DATE=\\\"" + dateString + "\\\" ";

		// Add C defines
		for (def in getActiveCDefs()) {
			if (def.value != null) {
				defines += "-D" + def.name + "=" + def.value + " ";
			} else {
				defines += "-D" + def.name + " ";
			}
		}

		return defines.trim();
	}

	/**
	 * Generates the defines string for C++
	 */
	public function generateCppDefines():String {
		var defines = "";

		for (def in getActiveCppDefs()) {
			if (def.value != null) {
				defines += "-D" + def.name + "=" + def.value + " ";
			} else {
				defines += "-D" + def.name + " ";
			}
		}

		return defines.trim();
	}

	/**
	 * Generates the haxelib string for Haxe compiler (one per line)
	 * Format: "-lib name" or "-lib name:version"
	 * Also generates defines for each library with its version
	 */
	public function generateHaxeLibsString():String {
		var lines:Array<String> = [];

		for (lib in getActiveHaxeLibs()) {
			var line = "-lib " + lib.name;
			if (lib.version != null) {
				line += ":" + lib.version;
			}
			lines.push(line);
		}

		return lines.join("\n");
	}

	/**
	 * Generates haxe defines for each library with its version
	 * Format: -D libraryname=version or -D libraryname if no version
	 */
	public function generateHaxeLibDefsString():String {
		var lines:Array<String> = [];

		for (lib in getActiveHaxeLibs()) {
			if (lib.version != null) {
				lines.push('-D ${lib.name}="${lib.version}"');
			} else {
				lines.push('-D ${lib.name}');
			}
		}

		return lines.join("\n");
	}

	/**
	 * Generates the switch libs string for MakeFile
	 * Format: "-lname1 -lname2"
	 */
	public function generateSwitchLibsString():String {
		var libs = "";

		for (lib in config.switchLibs) {
			libs += "-l" + lib.name + " ";
		}

		return libs.trim();
	}

	/**
	 * Generates the haxe defines string for Haxe compiler (one per line)
	 * Format: "-D NAME" or "-D NAME=value"
	 */
	public function generateHaxeDefsString():String {
		var lines:Array<String> = [];

		for (def in getActiveHaxeDefs()) {
			var line = "-D " + def.name;
			if (def.value != null) {
				line += "=" + def.value;
			}
			lines.push(line);
		}

		return lines.join("\n\t");
	}

	/**
	 * Generates the haxe flags string for Haxe compiler (one per line)
	 * Format: "--flag value" or just "--flag"
	 */
	public function generateHaxeFlagsString():String {
		var lines:Array<String> = [];

		for (flag in getActiveHaxeFlags()) {
			var line = flag.name;
			if (flag.value != null) {
				line += " " + flag.value;
			}
			lines.push(line);
		}

		return lines.join("\n\t");
	}

	/**
	 * Generates the C flags string for MakeFile
	 */
	public function generateCFlagsString():String {
		var flags = "";

		for (flag in getActiveCFlags()) {
			flags += flag.name;
			if (flag.value != null) {
				flags += " " + flag.value;
			}
			flags += " ";
		}

		return flags.trim();
	}

	/**
	 * Generates the C++ flags string for MakeFile
	 */
	public function generateCppFlagsString():String {
		var flags = "";

		for (flag in getActiveCppFlags()) {
			flags += flag.name;
			if (flag.value != null) {
				flags += " " + flag.value;
			}
			flags += " ";
		}

		return flags.trim();
	}

	/**
	 * Creates an example XML file
	 */
	public static function createExample():Void {
		var path = CommandLineUtils.getPathFromCurrentTerminal() + "/" + projectFileName;

		if (FileSystem.exists(path)) {
			Logger.log("[" + projectFileName + "] already exists!", WARNING);
			return;
		}

		Logger.log("Creating [" + projectFileName + "]...", PROCESSING);

		var xml = Resource.getString("XML_EXAMPLE");

		try {
			File.saveContent(path, xml);
			Logger.log("Created [" + projectFileName + "]", SUCCESS);
		} catch (e) {
			Logger.exitBecauseError("Error creating [" + projectFileName + "]: " + e);
		}
	}

	/**
	 * Initializes the singleton instance
	 */
	public static function init():ProjectFile {
		if (instance == null) {
			instance = new ProjectFile();
		}
		return instance;
	}

	/**
	 * Imports a project XML file from a Haxe library
	 * @param libName Name of the library to import from
	 */
	public static function importFromLibrary(libName:String):Void {
		if (libName == null || libName == "") {
			Logger.exitBecauseError('Invalid library name');
		}

		var basePath = CommandLineUtils.getPathFromCurrentTerminal();
		var haxelibPath = Sys.getEnv("HAXEPATH") + "/lib";

		var mainPath = FileSystem.exists(Path.join([basePath, ".haxelib"])) ? Path.join([basePath, ".haxelib"]) : haxelibPath;

		var libFolder = Path.join([mainPath, libName]);
		if (!FileSystem.exists(libFolder)) {
			Logger.exitBecauseError('Library [${libName}] not found in haxelib path');
		}

		// Determine version folder
		var versionFolder = "";
		if (FileSystem.exists(Path.join([libFolder, ".current"]))) {
			var currentContent = File.getContent(Path.join([libFolder, ".current"])).trim();
			if (currentContent == "git") {
				versionFolder = "git";
			} else {
				versionFolder = currentContent.replace(".", ",");
			}
		} else {
			Logger.exitBecauseError('Could not determine version for library [${libName}]');
		}

		// Build path to project XML
		var projectXMLPath = Path.join([libFolder, versionFolder, projectFileName]);

		if (!FileSystem.exists(projectXMLPath)) {
			Logger.exitBecauseError('[${projectFileName}] not found in library [${libName}/${versionFolder.replace(",", ".")}]');
		}

		// Check if project XML already exists in current directory
		var destPath = Path.join([basePath, projectFileName]);
		if (FileSystem.exists(destPath)) {
			Logger.exitBecauseError('[${projectFileName}] already exists in current directory!');
		}

		// Copy the file
		try {
			File.copy(projectXMLPath, destPath);
			Logger.log('Imported [${projectFileName}] from library [${libName}]', SUCCESS);
		} catch (e) {
			Logger.exitBecauseError('Error importing [${projectFileName}] from library [${libName}]: ${e}');
		}
	}
}