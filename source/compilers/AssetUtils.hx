// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.compilers;

import haxe.Resource;
import haxe.io.Bytes;

/**
 * Internal embedded assets used by HaxeNXCompiler
 */
enum abstract InternalAsset(Dynamic) {
	/**
	 * The embedded Makefile used for building the Switch files
	 */
	public static var MAKEFILE_NRO(get, never):String;

	private static function get_MAKEFILE_NRO():String {
		return Resource.getString("MakefileNRO");
	}

	/**
	 * The embedded C++ code of the wrapper used for initializing HXCPP  
	 */
	public static var WRAPPER_CODE_CPP(get, never):String;

	private static function get_WRAPPER_CODE_CPP():String {
		return Resource.getString("WrapperCodeCPP");
	}

	/**
	 * The embedded JPG logo of HaxeNXCompiler for the .nro icon
	 */
	public static var HXNX_LOGO_JPG(get, never):Bytes;

	private static function get_HXNX_LOGO_JPG():Bytes {
		return Resource.getBytes("HxNXLogoJPG");
	}

	/**
	 * The embedded haxe HXML file used for building the HXCPP project
	 */
	public static var HAXE_HXML(get, never):String;

	private static function get_HAXE_HXML():String {
		return Resource.getString("HaxeHXML");
	}
}

/**
 * Utility class for working with embedded assets
 */
class AssetUtils {
	/**
	 * Replaces a tag in a string
	 * 
	 * Example:
	 * ```haxe 
	 * replaceTag("Hello [NAME]", "NAME", "World");
	 * ```
	 * 
	 * @param mainString The string to replace the tag in
	 * @param tag The tag to replace, without the square brackets
	 * @param newStr The new string to replace the tag with
	 * 
	 * @return The string with the tag replaced, or the original string if the tag is not found
	 */
	public static function replaceTag(mainString:String, tag:String, newStr:String):String {
		if (mainString != null && mainString != "" && tag != null
			&& mainString.indexOf("[" + tag.replace("[", "").replace("]", "") + "]") != -1) {
			return mainString.replace("[" + tag.replace("[", "").replace("]", "") + "]", newStr);
		}

		// Tag not found, return original string
		// Logger.log("Tag " + tag + " not found in string " + mainString, DEBUG);
		return mainString;
	}
}
