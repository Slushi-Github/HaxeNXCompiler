// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.
package src.utils;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import src.JsonFile;

using StringTools;

/**
 * Utility to analyze Atmosphere crash reports.
 * 
 * Author: Slushi.
 */
class CrashAnalyzer {
	private static var jsonFile:JsonStruct = JsonFile.getJson();

    public static function initWithFile():Void {

        var fileResult:String = "";

        while (true) {
            Sys.print("Enter crash report file path: ");
			fileResult = Sys.stdin().readLine().toString();
            if (!FileSystem.exists(fileResult))
                SlushiUtils.printMsg("File not found: " + fileResult, SUCCESS);
            else if (fileResult == "" || fileResult == null)
                SlushiUtils.printMsg("Invalid file path", ERROR);
            else
                break;
            
        }

        analyzeCrashFile(fileResult, getElfPath(), getAddr2linePath());
    }

	/**
	 * Analyzes a crash report file or single address.
	 * @param input Path to crash report file or hex address (0x...)
	 */
	public static function analyze(input:String):Void {
		if (input == null || input == "") {
			SlushiUtils.printMsg("Usage: Provide crash report file or address (0x...)", ERROR);
			return;
		}

		var elfPath = getElfPath();
		if (elfPath == null)
			return;

		var addr2line = getAddr2linePath();
		if (addr2line == null)
			return;

		// Single address or file?
		if (FileSystem.exists(input)) {
			analyzeCrashFile(input, elfPath, addr2line);
		} else if (input.toLowerCase().startsWith("0x")) {
			analyzeSingleAddr(input, elfPath, addr2line);
		} else {
			SlushiUtils.printMsg("Invalid input. Provide file path or hex address", ERROR);
		}
	}

	private static function getElfPath():Null<String> {
		var path = SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig?.cppOutDir + "/switchFiles/" + jsonFile.switchConfig?.projectName
			+ ".elf";

		if (!FileSystem.exists(path)) {
			SlushiUtils.printMsg("ELF file not found: " + path, ERROR);
			return null;
		}
		return path;
	}

	private static function getAddr2linePath():Null<String> {
		var devkit = Sys.getEnv("DEVKITPRO");
		if (devkit == null) {
			SlushiUtils.printMsg("DEVKITPRO environment variable not set", ERROR);
			return null;
		}

		var path = devkit + "/devkitA64/bin/aarch64-none-elf-addr2line";
		if (!FileSystem.exists(path)) {
			SlushiUtils.printMsg("addr2line not found: " + path, ERROR);
			return null;
		}
		return path;
	}

	private static function analyzeSingleAddr(address:String, elfPath:String, addr2line:String):Void {
		Sys.println("Analyzing: " + address);
		Sys.println("---");
		Sys.command(addr2line, ["-e", elfPath, "-f", "-C", address]);
		Sys.println("---");
	}

	private static function analyzeCrashFile(file:String, elfPath:String, addr2line:String):Void {
		SlushiUtils.printMsg("Reading crash report...", PROCESSING);

		var content = try File.getContent(file) catch (e:Dynamic) {
			SlushiUtils.printMsg("Failed to read file: " + e, ERROR);
			return;
		};

		var addresses = extractAddresses(content);
		if (addresses.length == 0) {
			SlushiUtils.printMsg("No addresses found in report", ERROR);
			return;
		}

		Sys.println("\nCRASH REPORT:");
		Sys.println("Found " + addresses.length + " addresses\n");

		// Analyze main crash location
		Sys.println("\x1b[38;5;1mPOSIBLE\033[0m CRASH LOCATION:");
		for (i in 0...Std.int(Math.min(5, addresses.length))) {
			analyzeAddr(addresses[i], i + 1, elfPath, addr2line);
		}

		// Find user code
		Sys.println("PROJECT [" + jsonFile.switchConfig?.projectName + "] CODE:");
		var found = findUserCode(addresses, elfPath, addr2line);
		if (!found) {
			Sys.println("  x1b[38;5;178m(No project code found in stack trace)\033[0m");
		}

		Sys.println("\n");
	}

	private static function analyzeAddr(addr:String, num:Int, elfPath:String, addr2line:String):Void {
		Sys.println("\n" + num + ". --> " + addr);

		var proc = new sys.io.Process(addr2line, ["-e", elfPath, "-f", "-C", addr]);
		var output = proc.stdout.readAll().toString();
		proc.close();

		var lines = output.split("\n");
		for (line in lines) {
			line = StringTools.trim(line);
			if (line == "" || line == "??")
				continue;

			// Simplify paths
			if (line.indexOf("/") != -1) {
				line = simplifyPath(line);
			}
			Sys.println("  " + line);
		}
	}

	private static function findUserCode(addresses:Array<String>, elfPath:String, addr2line:String):Bool {
		var found = false;

		for (addr in addresses) {
			var proc = new sys.io.Process(addr2line, ["-e", elfPath, "-f", "-C", addr]);
			var output = proc.stdout.readAll().toString();
			proc.close();

			// Check if it's user code (in /src/ folder)
			if (output.indexOf("/src/") != -1 && output.indexOf("libnx") == -1) {
				if (!found)
					found = true;

				var lines = output.split("\n");
				Sys.println("\n  --> " + addr);
				for (line in lines) {
					line = StringTools.trim(line);
					if (line == "" || line == "??")
						continue;
					Sys.println("    " + simplifyPath(line));
				}
			}
		}

		return found;
	}

	private static function extractAddresses(content:String):Array<String> {
		var addresses:Array<String> = [];
		var lines = content.split("\n");

		for (line in lines) {
			// Extract PC
			if (line.indexOf("PC:") != -1 && line.indexOf("Project + 0x") != -1) {
				var match = ~/Project \+ (0x[0-9a-fA-F]+)/;
				if (match.match(line)) {
					addresses.push(match.matched(1));
				}
			}

			// Extract ReturnAddress
			if (line.indexOf("ReturnAddress[") != -1 && line.indexOf("Project + 0x") != -1) {
				var match = ~/Project \+ (0x[0-9a-fA-F]+)/;
				if (match.match(line)) {
					var addr = match.matched(1);
					if (addr != "0x0" && addr != "0x00000000") {
						addresses.push(addr);
					}
				}
			}
		}

		return addresses;
	}

	private static function simplifyPath(path:String):String {
		// Show only filename and line number for common paths
		if (path.indexOf("libnx") != -1) {
			var file = Path.withoutDirectory(path);
			return "[libnx] " + file;
		}

		if (path.indexOf("/src/") != -1) {
			var idx = path.indexOf("/src/");
			return path.substr(idx);
		}

		if (path.indexOf(".haxelib") != -1) {
			var file = Path.withoutDirectory(path);
			return "[hxcpp] " + file;
		}

		// Show full path if we don't know what it is
		return path;
	}
}