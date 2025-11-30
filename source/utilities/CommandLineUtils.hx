// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.utilities;

/**
 * Utilities for the command line.
 * 
 * Author: Slushi
 */
class CommandLineUtils {
	/**
	 * Returns the path of the current terminal.
	 * @return String
	 */
	public static function getPathFromCurrentTerminal():String {
		return Sys.getCwd().replace("\\", "/");
	}

	/**
	 * Deletes a file or directory recursively.
	 * @param path 
	 */
	public static function deleteRecursively(path:String):Void {
		if (FileSystem.exists(path)) {
			if (FileSystem.isDirectory(path)) {
				for (file in FileSystem.readDirectory(path)) {
					deleteRecursively(path + "/" + file);
				}
				FileSystem.deleteDirectory(path);
			} else {
				FileSystem.deleteFile(path);
			}
		}
	}

	/**
	 * Cleans the build directory.
	 */
	public static function cleanBuild():Void {
		var outDir = getPathFromCurrentTerminal() + ProjectFile.instance.config.cppOutput;
		var buildDir = getPathFromCurrentTerminal() + "build";

		if (FileSystem.exists(outDir)) {
			try {
				deleteRecursively(outDir);
				Logger.log("Deleted [" + outDir + "]", SUCCESS);
			} catch (e:Dynamic) {
				Logger.exitBecauseError("Failed to delete [" + outDir + "]: " + e);
			}
		}

		if (FileSystem.exists(buildDir)) {
			try {
				deleteRecursively(buildDir);
                Logger.log("Deleted [" + buildDir + "]", SUCCESS);
			} catch (e:Dynamic) {
                Logger.exitBecauseError("Failed to delete [" + buildDir + "]: " + e);
			}
		}
	}
}