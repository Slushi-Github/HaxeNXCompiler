// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.
package src.utils;

import haxe.io.Path;
import sys.FileSystem;
import src.JsonFile;

/**
 * The DevKitProUtils class is used to use the DevKitPro tools.
 * 
 * Author: Slushi.
 */
class DevKitProUtils {
	public static var jsonFile:JsonStruct = JsonFile.getJson();

	/**
	 * Searches for a problem in the code from a line address.
	 * @param address The address to search for.
	 */
	public static function searchProblem(address:String):Void {
		if (address == null || address == "") {
			SlushiUtils.printMsg("Invalid address", ERROR);
			return;
		}

		var elfPath:String = SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig?.cppOutDir + "/switchFiles/"
			+ jsonFile.switchConfig?.projectName + ".elf";
		if (!FileSystem.exists(elfPath)) {
			SlushiUtils.printMsg("[.elf] file not found", ERROR);
			return;
		}

		var devKitProEnv = Sys.getEnv("DEVKITPRO");
		var addr2lineProgram:String = devKitProEnv + "/devkitA64/bin/aarch64-none-elf-addr2line";

		if (devKitProEnv == null) {
			SlushiUtils.printMsg("DEVKITPRO environment variable not found", ERROR);
			return;
		}

		SlushiUtils.printMsg("If the output is \"??:0\", the address does not exist or is invalid", NONE);
		SlushiUtils.printMsg("----------------------", NONE);
		Sys.command(addr2lineProgram, ["-e", elfPath, address]);
		SlushiUtils.printMsg("----------------------", NONE);
	}

	/**
	 * Sends the compiled .nro file to the Switch console.
	 */
	public static function send(arg1:String):Void {
		var filePath:String = SlushiUtils.getPathFromCurrentTerminal() + "/" + jsonFile.haxeConfig?.cppOutDir + "/switchFiles/"
			+ jsonFile.switchConfig?.projectName + ".nro";

		if (!FileSystem.exists(filePath)) {
			SlushiUtils.printMsg("NRO file not found", ERROR);
			return;
		}

		var fileName:String = Path.withoutDirectory(filePath);

		SlushiUtils.printMsg("Sending file: [" + fileName + "]", PROCESSING);

		var devKitProToolsEnv = Sys.getEnv("DEVKITPRO");
		var nxlinkProgram = devKitProToolsEnv + "/tools/bin/nxlink";

		if (devKitProToolsEnv == null) {
			SlushiUtils.printMsg("DEVKITPRO environment variable not found", ERROR);
			return;
		}

		var arguments = ["-a", jsonFile.switchConfig.consoleIP, filePath];

		if (arg1 == "--server" || arg1 == "--s") {
			arguments.push("-s");
		}

		Sys.command(nxlinkProgram, arguments);
	}
}
