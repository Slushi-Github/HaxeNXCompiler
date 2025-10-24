// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


package utils;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.Json;
import haxe.crypto.Md5;

import src.JsonFile;
import src.SlushiUtils;
import src.compilers.HaxeCompiler;

using StringTools;

/**
 * The AssetsManager class is used to manage the assets of the project
 * 
 * Author: Slushi
 */
class AssetsManager {
    static var jsonFile:JsonStruct = JsonFile.getJson();
    static var cache:Map<String, String> = new Map(); // path -> md5
    static var cacheFile:String;
    private static final jsonCacheFileName:String = "HxNX_AssetsCache.json";

    /*
     * List of files found in the assets
     */
    static var foundFiles:Array<String> = [];

    /**
     * Search for assets and copy them to the output folder
     */
    public static function searchAndGetAssets():Void {
		if (HaxeCompiler.getExitCode() != 0) {
			return;
		}

        var outputDir = jsonFile.haxeConfig.cppOutDir;
        var basePath = SlushiUtils.getPathFromCurrentTerminal();
        var outputPath = Path.join([basePath, outputDir]);
        cacheFile = Path.join([outputPath, jsonCacheFileName]);

        // Load cache
        if (FileSystem.exists(cacheFile)) {
            try {
                var content = File.getContent(cacheFile);
                var obj:Dynamic = Json.parse(content);
                for (k in Reflect.fields(obj)) {
                    cache.set(k, Reflect.field(obj, k));
                }
            } catch (e:Dynamic) {
                SlushiUtils.printMsg("Failed to load cache: " + e, WARN);
            }
        }

        if (!FileSystem.exists(outputPath)) {
            SlushiUtils.printMsg("Can't find output folder", ERROR);
            return;
        }

        var projectAssets = Path.join([basePath, "assets"]);
        if (FileSystem.exists(projectAssets)) {
            SlushiUtils.printMsg("Copying local assets [" + projectAssets + "] to [" + outputPath + "]", PROCESSING);
            copyRomfs(projectAssets, Path.join([outputPath, "romfs"]), "PROJECT");
        }

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
                else if (FileSystem.exists(Path.join([libFolder, ".current"])) )
                    File.getContent(Path.join([libFolder, ".current"])).trim().replace(".", ",")
                else "";

            var assetsPath = Path.join([libFolder, versionFolder, "assets"]);
            if (!FileSystem.exists(assetsPath)) continue;

            SlushiUtils.printMsg("Copying assets from [" + libName + "/" + versionFolder.replace(",", ".") + "/assets" + "] to [" + outputDir + "]", PROCESSING);

            for (file in FileSystem.readDirectory(assetsPath)) {
                var src = Path.join([assetsPath, file]);

                switch (file) {
                    case "ROMFS":
                        copyRomfs(src, Path.join([outputPath, "romfs"]), libName);
                    default:
                        SlushiUtils.printMsg("Unknown folder [" + file + "] in [" + libName + "/" + versionFolder.replace(",", ".") + "/assets" + "]", WARN);
                        continue;
                }
            }
        }

        // Clean removed assets
        cleanRemovedAssets(outputPath);

        // Save cache
        saveCache();
    }

    static function copyRomfs(src:String, dst:String, libName:String):Void {
        if (!FileSystem.exists(dst)) FileSystem.createDirectory(dst);
        for (f in FileSystem.readDirectory(src)) {
            var srcFile = Path.join([src, f]);
            var dstFile = Path.join([dst, f]);

            if (FileSystem.isDirectory(srcFile)) {
                if (!FileSystem.exists(dstFile)) FileSystem.createDirectory(dstFile);
                for (sub in FileSystem.readDirectory(srcFile)) {
                    var from = Path.join([srcFile, sub]);
                    var to = Path.join([dstFile, sub]);
                    var key = libName + "/ROMFS/" + f + "/" + sub;
                    copyIfChanged(from, to, key);
                }
            } else {
                var key = libName + "/ROMFS/" + f;
                copyIfChanged(srcFile, dstFile, key);
            }
        }
    }

    static function copyIfChanged(from:String, to:String, key:String):Void {
        var newHash = Md5.make(File.getBytes(from)).toHex();
        var oldHash = cache.exists(key) ? cache.get(key) : null;

        foundFiles.push(key);

        if (oldHash != null && oldHash == newHash && FileSystem.exists(to)) {
            SlushiUtils.printMsg("Skipped (unchanged): " + to, INFO);
            return;
        }

        File.copy(from, to);
        cache.set(key, newHash);
        SlushiUtils.printMsg("Copied: " + from + " -> " + to, SUCCESS);
    }

    // 🔥 Elimina archivos que estaban en cache pero ya no existen en origen
    static function cleanRemovedAssets(outputPath:String):Void {
        var toRemove:Array<String> = [];

        for (k in cache.keys()) {
            if (!foundFiles.contains(k)) {
                // Archivo estaba en cache pero no se detectó en esta ejecución
                var relative = k.split("/ROMFS/").length > 1 ? k.split("/ROMFS/")[1] : k;
                var dstFile = Path.join([outputPath, "romfs", relative]);
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

    static function saveCache():Void {
        var obj:Dynamic = {};
        for (k in cache.keys()) {
            Reflect.setField(obj, k, cache.get(k));
        }
        var json = Json.stringify(obj, null, "  ");
        File.saveContent(cacheFile, json);
    }
}
