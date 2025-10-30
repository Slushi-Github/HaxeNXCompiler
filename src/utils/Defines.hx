// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


package src.utils;

import src.JsonFile;
import src.compilers.MainCompiler;

/**
 * The Defines class is used to parse the defines that are required by the project.
 * 
 * Author: Slushi.
 */
class Defines {
	static var jsonFile:JsonStruct = JsonFile.getJson();

	/**
	 * Parses the Haxe defines from the JSON file.
	 * @return Array<String>
	 */
	public static function parseHXDefines():{main:Array<String>, hxDef:Array<String>, hxlibs:Array<String>} {
		var defines = {main: [], hxDef: [], hxlibs: []};

		for (define in jsonFile.projectDefines ?? new Array<String>()) {
			defines.main.push("-D " + define);
		}

		for (lib in MainCompiler.libs) {
			for (define in lib.libJSONData.mainDefines ?? new Array<String>()) {
				defines.main.push("-D " + define);
			}
		}

		for (lib in MainCompiler.libs) {
			for (define in lib.libJSONData.hxDefines ?? new Array<String>()) {
				defines.hxDef.push(define);
			}
		}

		/* 
		* I like this thing from Lime:
		* 
		* ````haxe
		* #if (hx_libnx >= "1.0.0")
		* #end
		* ```
		* 
		* so I'm going to recreate it here
		 */
		for (lib in MainCompiler.libs) {
			if (lib.hxLibName == null || lib.hxLibName == "" || lib.hxLibVersion == null || lib.hxLibVersion == "") {
				continue;
			}
			defines.hxlibs.push("-D " + lib.hxLibName + "=\"" + lib.hxLibVersion + "\"");
		}

		return defines;
	}

	/**
	 * Parses the C defines from the JSON file.
	 * @return Array<String>
	 */
	public static function parseMakeFileDefines():{main:Array<String>, c:Array<String>, cpp:Array<String>} {
		var defines = {main: [], c: [], cpp: []};

		for (define in jsonFile.projectDefines ?? new Array<String>()) {
			defines.main.push("-D" + define);
		}

		for (lib in MainCompiler.libs) {
			for (define in lib.libJSONData.mainDefines ?? new Array<String>()) {
				defines.main.push("-D" + define);
			}
		}

		for (lib in MainCompiler.libs) {
			for (define in lib.libJSONData.cDefines ?? new Array<String>()) {
				defines.c.push(define);
			}
		}

		for (lib in MainCompiler.libs) {
			for (define in lib.libJSONData.cppDefines ?? new Array<String>()) {
				defines.cpp.push(define);
			}
		}

		return defines;
	}

	/**
	 * Parses the other Haxe options from the JSON file.
	 * @return Array<String>
	 */
	public static function parseOtherOptions():Array<String> {
		var options:Array<String> = [];

		for (option in jsonFile.haxeConfig?.othersOptions ?? new Array<String>()) {
			options.push(option);
		}

		return options;
	}
}
