// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.

package source.utilities;

import sys.io.Process;

/**
 * Utility to analyze Atmosphere crash reports.
 * 
 * VERY EXPERIMENTAL
 * 
 * Author: Slushi.
 */
class CrashAnalyzer {
    public static function initWithFile():Void {
        var fileResult:String = "";

        while (true) {
			Logger.log("Enter crash report file path: ", NONE);
			fileResult = Sys.stdin().readLine().toString();
            if (!FileSystem.exists(fileResult))
                Logger.log("File not found: " + fileResult, SUCCESS);
            else if (fileResult == "" || fileResult == null)
                Logger.log("Invalid file path", ERROR);
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
			Logger.log("Usage: Provide crash report file or address (0x...)", ERROR);
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
			Logger.log("Invalid input. Provide file path or hex address", ERROR);
		}
	}

	private static function getElfPath():Null<String> {
		var path = CommandLineUtils.getPathFromCurrentTerminal() + "/" + ProjectFile.instance.config.cppOutput + "/switchFiles/" + ProjectFile.instance.config.switchProjectName
			+ ".elf";

		if (!FileSystem.exists(path)) {
			Logger.log("ELF file not found: " + path, ERROR);
			return null;
		}
		return path;
	}

	private static function getAddr2linePath():Null<String> {
		var devkit = Sys.getEnv("DEVKITPRO");
		if (devkit == null) {
			Logger.log("DEVKITPRO environment variable not set", ERROR);
			return null;
		}

		var path = devkit + "/devkitA64/bin/aarch64-none-elf-addr2line";
		if (!FileSystem.exists(path)) {
			Logger.log("addr2line not found: " + path, ERROR);
			return null;
		}
		return path;
	}

	private static function analyzeSingleAddr(address:String, elfPath:String, addr2line:String):Void {
		Logger.log("Analyzing: " + address, NONE);
		Logger.log("---", NONE);
		Sys.command(addr2line, ["-e", elfPath, "-f", "-C", address]);
		Logger.log("---", NONE);
	}

	private static function analyzeCrashFile(file:String, elfPath:String, addr2line:String):Void {
		Logger.log("Reading crash report...", PROCESSING);

		var content = try File.getContent(file) catch (e:Dynamic) {
			Logger.log("Failed to read file: " + e, ERROR);
			return;
		};

		var addresses = extractAddresses(content);
		if (addresses.length == 0) {
			Logger.log("No addresses found in report", ERROR);
			return;
		}

		Logger.log("\nCRASH REPORT:", NONE);
		Logger.log("Found " + addresses.length + " addresses\n", NONE);

		// Analyze main crash location
		Logger.log("\x1b[38;5;1mPOSIBLE\033[0m CRASH LOCATION:", NONE);
		for (i in 0...Std.int(Math.min(5, addresses.length))) {
			analyzeAddr(addresses[i], i + 1, elfPath, addr2line);
		}

		// Find user code
		Logger.log("PROJECT [" + ProjectFile.instance.config.switchProjectName + "] CODE:", NONE);
		var found = findUserCode(addresses, elfPath, addr2line);
		if (!found) {
			Logger.log("  x1b[38;5;178m(No project code found in stack trace)\033[0m", NONE);
		}

		Logger.log("\n", NONE);
	}

	private static function analyzeAddr(addr:String, num:Int, elfPath:String, addr2line:String):Void {
		Logger.log("\n" + num + ". --> " + addr, NONE);

		var proc = new Process(addr2line, ["-e", elfPath, "-f", "-C", addr]);
		var output = proc.stdout.readAll().toString();
		proc.close();

		var lines = output.split("\n");
		for (line in lines) {
			line = line.trim();
			if (line == "" || line == "??")
				continue;

			// Simplify paths
			if (line.indexOf("/") != -1) {
				line = simplifyPath(line);
			}
			Logger.log("  " + line, NONE);
		}
	}

	private static function findUserCode(addresses:Array<String>, elfPath:String, addr2line:String):Bool {
		var found = false;

		for (addr in addresses) {
			var proc = new Process(addr2line, ["-e", elfPath, "-f", "-C", addr]);
			var output = proc.stdout.readAll().toString();
			proc.close();

			// Check if it's user code (in /src/ folder)
			if (output.indexOf("/src/") != -1 && output.indexOf("libnx") == -1) {
				if (!found)
					found = true;

				var lines = output.split("\n");
				Logger.log("\n  --> " + addr, NONE);
				for (line in lines) {
					line = StringTools.trim(line);
					if (line == "" || line == "??")
						continue;
					Logger.log("    " + simplifyPath(line), NONE);
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