// Copyright (c) 2025 Andrés E. G.
//
// This software is licensed under the MIT License.
// See the LICENSE file for more details.


#if !macro
import haxe.Json;
import haxe.Resource;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

import source.compilers.haxe.HaxeCompiler;
import source.compilers.nx.NXLinker;

import source.compilers.AssetUtils;
import source.compilers.BaseCompiler;
import source.compilers.MainCompiler;

import source.managers.AssetsManager;
import source.managers.LibsManager;

import source.utilities.CommandLineUtils;
import source.utilities.DevKitProUtils;
import source.utilities.CrashAnalyzer;

import source.ProjectFile;
import source.Main;
import source.Logger;

using StringTools;
#end