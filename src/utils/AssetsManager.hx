package utils;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.Json;
import haxe.crypto.Md5;
import haxe.Resource;

import src.JsonFile;
import src.SlushiUtils;

using StringTools;

/**
 * AssetsManager, copies and manages assets into the outptut folder
 * from the assets folder of the project and its libraries.
 * 
 * Author: Slushi
 */
class AssetsManager {
    static var jsonFile:JsonStruct = JsonFile.getJson();
    static var cache:Map<String, String> = new Map(); // path -> md5
    static var cacheFile:String;
    private static final jsonCacheFileName:String = "HxNX_AssetsCache.json";

    static var foundFiles:Array<String> = [];
    static var iconFound:Bool = false;

    public static function searchAndGetAssets():Void {
        var outputDir = jsonFile.haxeConfig.cppOutDir;
        var basePath = SlushiUtils.getPathFromCurrentTerminal();
        var outputPath = Path.join([basePath, outputDir]);
        cacheFile = Path.join([outputPath, jsonCacheFileName]);

        // Load cache
        if (FileSystem.exists(cacheFile)) {
            try {
                var content = File.getContent(cacheFile);
                var obj:Dynamic = Json.parse(content);
                for (k in Reflect.fields(obj)) cache.set(k, Reflect.field(obj, k));
            } catch (e:Dynamic) {
                SlushiUtils.printMsg("Failed to load cache: " + e, WARN);
            }
        }

        if (!FileSystem.exists(outputPath)) {
            SlushiUtils.printMsg("Can't find output folder", ERROR);
            return;
        }

        var projectAssets = Path.join([basePath, "assets"]);
        var switchAssetsPath = Path.join([outputPath, "SWITCH_ASSETS/romfs"]);
        var switchRootPath = Path.join([outputPath, "SWITCH_ASSETS"]);
        ensureDir(switchAssetsPath);

        // Copy project assets
        if (FileSystem.exists(projectAssets)) {
            SlushiUtils.printMsg("Copying local assets [" + projectAssets + "] to [" + switchAssetsPath + "]", PROCESSING);
            copyRomfsRecursive(projectAssets, switchAssetsPath, "PROJECT");
            checkAndCopyIcon(projectAssets, switchRootPath);
        }

        // Copy from libraries
        var mainPath = if (FileSystem.exists(Path.join([basePath, ".haxelib"])))
            Path.join([basePath, ".haxelib"])
        else
            Path.join([Sys.getEnv("HAXEPATH"), "lib"]);

        for (libEntry in jsonFile.extraLibs) {
            var parts = libEntry.split(":");
            var libName = parts[0];
            var libVersion = parts.length > 1 ? parts[1] : null;

            var libFolder = Path.join([mainPath, libName]);
            if (!FileSystem.exists(libFolder)) {
                SlushiUtils.printMsg("Required Haxe lib [" + libName + "] not found.", WARN);
                continue;
            }

            var versionFolder =
                if (libVersion != null) libVersion.replace(".", ",")
                else if (FileSystem.exists(Path.join([libFolder, ".current"])))
                    File.getContent(Path.join([libFolder, ".current"])).trim().replace(".", ",")
                else "";

            var assetsPath = Path.join([libFolder, versionFolder, "assets"]);
            if (!FileSystem.exists(assetsPath)) continue;

            SlushiUtils.printMsg("Copying assets from [" + libName + "/" + versionFolder.replace(",", ".") + "/assets" + "] to [" + switchAssetsPath + "]", PROCESSING);

            for (file in FileSystem.readDirectory(assetsPath)) {
                var src = Path.join([assetsPath, file]);
                switch (file) {
                    case "ROMFS":
                        copyRomfsRecursive(src, switchAssetsPath, libName);
                    default:
                        SlushiUtils.printMsg("Unknown folder [" + file + "] in [" + libName + "/" + versionFolder.replace(",", ".") + "/assets" + "]", WARN);
                }
            }

            // Also check for icons in library assets
            checkAndCopyIcon(assetsPath, switchRootPath);
        }

        // If no icon was found, create default
        if (!iconFound) {
            try {
                var defaultIcon = Resource.getBytes("HxNXLogoJPG");
                var defaultIconPath = Path.join([switchRootPath, "icon.jpg"]);
                File.saveBytes(defaultIconPath, defaultIcon);
                SlushiUtils.printMsg("No icon found, default icon created at [" + defaultIconPath + "]", INFO);
            } catch (e:Dynamic) {
                SlushiUtils.printMsg("Failed to create default icon: " + e, ERROR);
            }
        }

        // Remove missing assets
        cleanRemovedAssets(switchAssetsPath);

        // Save cache
        saveCache();
    }

    /**
     * Recursively copies files preserving folder structure.
     */
    static function copyRomfsRecursive(src:String, dst:String, libName:String, ?relativePath:String = ""):Void {
        ensureDir(dst);
        for (entry in FileSystem.readDirectory(src)) {
            var srcEntry = Path.join([src, entry]);
            var dstEntry = Path.join([dst, entry]);
            var rel = relativePath == "" ? entry : Path.join([relativePath, entry]);
            var key = libName + "/ROMFS/" + rel;

            if (FileSystem.isDirectory(srcEntry)) {
                ensureDir(dstEntry);
                copyRomfsRecursive(srcEntry, dstEntry, libName, rel);
            } else {
                copyIfChanged(srcEntry, dstEntry, key);
            }
        }
    }

    /**
     * Creates a directory if it doesn't exist.
     * @param path 
     */
    static function ensureDir(path:String):Void {
        if (!FileSystem.exists(path)) {
            try {
                FileSystem.createDirectory(path);
                if (!FileSystem.exists(path)) {
                    SlushiUtils.printMsg("Failed to create directory: " + path, ERROR);
                } else {
                    SlushiUtils.printMsg("Created directory: " + path, SUCCESS);
                }
            } catch (e:Dynamic) {
                SlushiUtils.printMsg("Error creating directory [" + path + "]: " + e, ERROR);
            }
        }
    }

    /**
     * Copies a file if it has changed.
     * @param from 
     * @param to 
     * @param key 
     */
    static function copyIfChanged(from:String, to:String, key:String):Void {
        var newHash = Md5.make(File.getBytes(from)).toHex();
        var oldHash = cache.exists(key) ? cache.get(key) : null;
        foundFiles.push(key);

        if (oldHash != null && oldHash == newHash && FileSystem.exists(to)) {
            SlushiUtils.printMsg("Skipped (unchanged): " + to, INFO);
            return;
        }

        try {
            File.copy(from, to);
            cache.set(key, newHash);
            SlushiUtils.printMsg("Copied: " + from + " -> " + to, SUCCESS);
        } catch (e:Dynamic) {
            SlushiUtils.printMsg("Error copying file [" + from + "]: " + e, ERROR);
        }
    }

    /**
     * Removes assets that have been removed.
     * @param outputPath 
     */
    static function cleanRemovedAssets(outputPath:String):Void {
        var toRemove:Array<String> = [];

        for (k in cache.keys()) {
            if (!foundFiles.contains(k)) {
                var relative = k.split("/ROMFS/").length > 1 ? k.split("/ROMFS/")[1] : k;
                var dstFile = Path.join([outputPath, relative]);
                if (FileSystem.exists(dstFile)) {
                    try {
                        FileSystem.deleteFile(dstFile);
                        SlushiUtils.printMsg("Removed missing asset: " + dstFile, WARN);
                    } catch (e:Dynamic) {
                        SlushiUtils.printMsg("Failed to remove old asset: " + dstFile + " (" + e + ")", ERROR);
                    }
                }
                toRemove.push(k);
            }
        }

        for (r in toRemove) cache.remove(r);
    }

    /**
     * Checks and copies icon from given assets path.
     * @param assetsPath 
     * @param switchRootPath 
     */
    static function checkAndCopyIcon(assetsPath:String, switchRootPath:String):Void {
        var projectName = jsonFile.switchConfig.projectName;
        var possibleIcons = [
            Path.join([assetsPath, "icon.jpg"]),
            Path.join([assetsPath, projectName + ".jpg"])
        ];

        for (iconPath in possibleIcons) {
            if (FileSystem.exists(iconPath)) {
                var dst = Path.join([switchRootPath, "icon" + Path.extension(iconPath)]);
                File.copy(iconPath, dst);
                iconFound = true;
                SlushiUtils.printMsg("Copied icon: " + iconPath + " -> " + dst, SUCCESS);
                return;
            }
        }
    }

    /**
     * Saves the cache file.
     */
    static function saveCache():Void {
        var obj:Dynamic = {};
        for (k in cache.keys()) Reflect.setField(obj, k, cache.get(k));
        var json = Json.stringify(obj, null, "  ");
        File.saveContent(cacheFile, json);
    }
}
