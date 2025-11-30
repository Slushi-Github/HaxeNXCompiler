// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.managers;

import haxe.crypto.Md5;

using StringTools;

/**
 * Asset cache structure
 */
typedef AssetCache = {
	files:Map<String, String> // path -> md5
}

/**
 * Icon candidate structure
 */
typedef IconCandidate = {
	path:String,
	source:String, // "project" or library name
	priority:Int // 0 = project, 1+ = libraries
}

/**
 * AssetsManager - Copies and manages assets into the output folder
 * from the assets folder of the project and its libraries.
 * Detects changes using MD5 hashing.
 * 
 * Author: Slushi, Claude
 */
class AssetsManager {
	public static var instance:AssetsManager = null;

	private var cache:Map<String, String> = new Map(); // path -> md5
	private var foundFiles:Array<String> = [];
	private var cacheFile:String;
	private var outputPath:String;
	private var switchAssetsPath:String;
	private var switchRootPath:String;

	private static final CACHE_FILE_NAME:String = "HxNX_AssetsCache.json";
	private static final ROMFS_FOLDER:String = "SWITCH_ASSETS/romfs";
	private static final SWITCH_ROOT:String = "SWITCH_ASSETS";

	public function new() {
		instance = this;
	}

	/**
	 * Main function to search and copy all assets
	 */
	public function processAssets():Void {
		var basePath = CommandLineUtils.getPathFromCurrentTerminal();
		outputPath = Path.join([basePath, ProjectFile.instance.config.cppOutput]);
		switchAssetsPath = Path.join([outputPath, ROMFS_FOLDER]);
		switchRootPath = Path.join([outputPath, SWITCH_ROOT]);
		cacheFile = Path.join([outputPath, CACHE_FILE_NAME]);

		// Ensure output directories exist
		if (!FileSystem.exists(outputPath)) {
			Logger.exitBecauseError("Can't find output folder: " + outputPath);
		}

		ensureDir(switchAssetsPath);
		ensureDir(switchRootPath);

		Logger.log("----------------------", NONE);
		Logger.log("Processing assets...", PROCESSING);

		// Load cache
		loadCache();

		var iconCandidates:Array<IconCandidate> = [];

		// 1. Copy project assets (highest priority)
		var basePath = CommandLineUtils.getPathFromCurrentTerminal();
		var projectAssetsPath = Path.join([basePath, "assets"]);

		if (FileSystem.exists(projectAssetsPath)) {
			Logger.log("Processing project assets from [assets/]", PROCESSING);
			processAssetsFolder(projectAssetsPath, "PROJECT", 0);

			// Check for project icon
			var projectIcon = findIcon(projectAssetsPath);
			if (projectIcon != null) {
				iconCandidates.push({
					path: projectIcon,
					source: "PROJECT",
					priority: 0
				});
			}
		} else {
			Logger.log("No project assets folder found, skipping.", INFO);
		}

		// 2. Copy library assets
		if (LibsManager.instance != null && LibsManager.instance.libs.length > 0) {
			var priority = 1;
			for (lib in LibsManager.instance.libs) {
				var assetsPath = findLibraryAssetsPath(lib.hxLibName, lib.hxLibVersion);

				if (assetsPath != null && FileSystem.exists(assetsPath)) {
					Logger.log('Processing assets from library [${lib.hxLibName}:${lib.hxLibVersion}]', PROCESSING);
					processAssetsFolder(assetsPath, lib.hxLibName, priority);

					// Check for library icon
					var libIcon = findIcon(assetsPath);
					if (libIcon != null) {
						iconCandidates.push({
							path: libIcon,
							source: lib.hxLibName,
							priority: priority
						});
					}

					priority++;
				}
			}
		}

		// 3. Process icon (copy to SWITCH_ASSETS root, NOT romfs)
		processIcon(iconCandidates);

		// 4. Clean removed assets
		cleanRemovedAssets();

		// 5. Save cache
		saveCache();

		Logger.log("Assets processing completed!", SUCCESS);
		Logger.log("----------------------\n", NONE);
	}

	/**
	 * Processes an assets folder (project or library)
	 * @param assetsPath Path to the assets folder
	 * @param sourceName Name of the source (PROJECT or library name)
	 * @param priority Priority for conflict resolution (0 = highest)
	 */
	private function processAssetsFolder(assetsPath:String, sourceName:String, priority:Int):Void {
		if (!FileSystem.exists(assetsPath))
			return;

		for (entry in FileSystem.readDirectory(assetsPath)) {
			var entryPath = Path.join([assetsPath, entry]);

			// Skip icon files - they're handled separately
			if (entry == "icon.jpg" || entry.endsWith(".jpg"))
				continue;

			if (FileSystem.isDirectory(entryPath)) {
				// Check for ROMFS folder
				if (entry == "ROMFS" || entry == "romfs") {
					copyRomfsRecursive(entryPath, switchAssetsPath, sourceName, "");
				} else {
					Logger.log('Unknown folder [${entry}] in [${sourceName}/assets], skipping.', WARNING);
				}
			} else {
				Logger.log('File [${entry}] in [${sourceName}/assets] root is ignored (only ROMFS/ is supported)', WARNING);
			}
		}
	}

	/**
	 * Recursively copies ROMFS files, detecting changes via MD5
	 */
	private function copyRomfsRecursive(src:String, dst:String, sourceName:String, relativePath:String):Void {
		ensureDir(dst);

		for (entry in FileSystem.readDirectory(src)) {
			var srcEntry = Path.join([src, entry]);
			var dstEntry = Path.join([dst, entry]);
			var rel = relativePath == "" ? entry : Path.join([relativePath, entry]);
			var cacheKey = '${sourceName}/ROMFS/${rel}';

			if (FileSystem.isDirectory(srcEntry)) {
				ensureDir(dstEntry);
				copyRomfsRecursive(srcEntry, dstEntry, sourceName, rel);
			} else {
				copyIfChanged(srcEntry, dstEntry, cacheKey);
			}
		}
	}

	/**
	 * Copies a file only if its MD5 hash has changed
	 */
	private function copyIfChanged(from:String, to:String, cacheKey:String):Void {
		try {
			var newHash = Md5.make(File.getBytes(from)).toHex();
			var oldHash = cache.get(cacheKey);

			foundFiles.push(cacheKey);

			// Skip if unchanged and destination exists
			if (oldHash != null && oldHash == newHash && FileSystem.exists(to)) {
				return;
			}

			// Copy file
			File.copy(from, to);
			cache.set(cacheKey, newHash);
			// Logger.log('Copied: ${Path.withoutDirectory(from)} -> ${to}', SUCCESS);
		} catch (e) {
			Logger.log('Error copying file [${from}]: ${e}', ERROR);
		}
	}

	/**
	 * Finds an icon in the given assets path
	 * Looks for: icon.jpg or {projectName}.jpg
	 */
	private function findIcon(assetsPath:String):String {
		var projectName = ProjectFile.instance.config.switchProjectName;

		var possibleIcons = [
			Path.join([assetsPath, "icon.jpg"]),
			Path.join([assetsPath, projectName + ".jpg"])
		];

		for (iconPath in possibleIcons) {
			if (FileSystem.exists(iconPath)) {
				return iconPath;
			}
		}

		return null;
	}

	/**
	 * Processes icon with priority system
	 * Priority: Project icon > First library icon > Embedded default
	 */
	private function processIcon(candidates:Array<IconCandidate>):Void {
		// Sort by priority (lowest number = highest priority)
		candidates.sort((a, b) -> a.priority - b.priority);

		var iconDestPath = Path.join([switchRootPath, "icon.jpg"]);

		if (candidates.length > 0) {
			var chosen = candidates[0];
			try {
				File.copy(chosen.path, iconDestPath);
				Logger.log('Using icon from [${chosen.source}]: ${chosen.path}', SUCCESS);
			} catch (e) {
				Logger.log('Error copying icon from [${chosen.source}]: ${e}', ERROR);
				createDefaultIcon(iconDestPath);
			}
		} else {
			// No icon found, use embedded default
			createDefaultIcon(iconDestPath);
		}
	}

	/**
	 * Creates the default embedded icon
	 */
	private function createDefaultIcon(destPath:String):Void {
		try {
			var defaultIcon = InternalAsset.HXNX_LOGO_JPG;
			File.saveBytes(destPath, defaultIcon);
			Logger.log("No icon found, using default embedded icon", INFO);
		} catch (e) {
			Logger.log("Failed to create default icon: " + e, ERROR);
		}
	}

	/**
	 * Finds the assets path for a library
	 */
	private function findLibraryAssetsPath(libName:String, libVersion:String):String {
		var basePath = CommandLineUtils.getPathFromCurrentTerminal();
		var haxelibPath = Sys.getEnv("HAXEPATH") + "/lib";

		var mainPath = FileSystem.exists(Path.join([basePath, ".haxelib"])) ? Path.join([basePath, ".haxelib"]) : haxelibPath;

		var libFolder = Path.join([mainPath, libName]);
		if (!FileSystem.exists(libFolder))
			return null;

		var versionFolder = "";
		if (libVersion != null && libVersion != "git") {
			versionFolder = libVersion.replace(".", ",");
		} else if (FileSystem.exists(Path.join([libFolder, ".current"]))) {
			var currentContent = File.getContent(Path.join([libFolder, ".current"])).trim();
			if (currentContent == "git") {
				versionFolder = "git";
			} else {
				versionFolder = currentContent.replace(".", ",");
			}
		}

		return Path.join([libFolder, versionFolder, "assets"]);
	}

	/**
	 * Removes assets that no longer exist in source
	 */
	private function cleanRemovedAssets():Void {
		var toRemove:Array<String> = [];

		for (key in cache.keys()) {
			if (!foundFiles.contains(key)) {
				// Extract relative path from cache key (SOURCE/ROMFS/path -> path)
				var parts = key.split("/ROMFS/");
				if (parts.length < 2)
					continue;

				var relativePath = parts[1];
				var dstFile = Path.join([switchAssetsPath, relativePath]);

				if (FileSystem.exists(dstFile)) {
					try {
						FileSystem.deleteFile(dstFile);
						Logger.log('Removed missing asset: ${relativePath}', WARNING);
					} catch (e) {
						Logger.log('Failed to remove old asset [${relativePath}]: ${e}', ERROR);
					}
				}

				toRemove.push(key);
			}
		}

		for (key in toRemove) {
			cache.remove(key);
		}

		// if (toRemove.length > 0) {
		// 	Logger.log('Cleaned up ${toRemove.length} removed asset(s)', INFO);
		// }
	}

	/**
	 * Ensures a directory exists
	 */
	private function ensureDir(path:String):Void {
		if (!FileSystem.exists(path)) {
			try {
				FileSystem.createDirectory(path);
			} catch (e) {
				Logger.exitBecauseError('Failed to create directory [${path}]: ${e}');
			}
		}
	}

	/**
	 * Loads the cache from disk
	 */
	private function loadCache():Void {
		if (!FileSystem.exists(cacheFile))
			return;

		try {
			var content = File.getContent(cacheFile);
			var cacheData:AssetCache = Json.parse(content);

			// Reconstruct map from dynamic object
			if (cacheData.files != null) {
				for (key in Reflect.fields(cacheData.files)) {
					cache.set(key, Reflect.field(cacheData.files, key));
				}
			}

			// Logger.log('Loaded asset cache with ${Lambda.count(cache)} entries', INFO);
		} catch (e) {
			Logger.log("Failed to load asset cache: " + e, WARNING);
		}
	}

	/**
	 * Saves the cache to disk
	 */
	private function saveCache():Void {
		try {
			var filesObj:Dynamic = {};
			for (key in cache.keys()) {
				Reflect.setField(filesObj, key, cache.get(key));
			}

			var cacheData:AssetCache = {
				files: filesObj
			};

			var json = Json.stringify(cacheData, null, "  ");
			File.saveContent(cacheFile, json);

			// Logger.log('Saved asset cache with ${Lambda.count(cache)} entries', INFO);
		} catch (e) {
			Logger.log("Failed to save asset cache: " + e, ERROR);
		}
	}
}