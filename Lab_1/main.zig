/// Rachamim Seltzer: 662215912
/// Efrem Mincer: 3246291982
/// Fundamentals of Software Programming Lab 1

const std = @import("std");
const parserModule = @import("parser.zig");
const codeWriterModule = @import("codeWriter.zig");
const mainUtils = @import("utils.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;

const print = std.debug.print;

const readAndCleanUserInput = mainUtils.readAndCleanUserInput;
const findFilesAndParse = mainUtils.findFilesAndParse;
const getDirectoryName = mainUtils.getDirectoryName;
const createNewLines = mainUtils.createNewLines;

/// Main entry point for the VM Translator.
/// Asks the user for a directory path, parses `.vm` files, translates VM commands to Hack assembly,
/// and writes the output to `.asm` files with the same name as the input files.
pub fn main() !void {

    // Setup input and output streams
    const stdout = std.io.getStdOut().writer();

    // Prompt the user for a directory path
    try stdout.print("Enter path for file(s): ", .{});

    // Read user input
    const path_val = readAndCleanUserInput() catch |err|{
        print("arg failed, error: {}", .{err});
        return;
    };

    // Try to open the provided directory
    var dir = std.fs.openDirAbsolute(path_val,  .{.iterate = true}) catch |err| {
        print("ERROR opening directory: {}\n", .{err});
        return error.InvalidDirectory;
    };
    defer dir.close();

    const dir_name = getDirectoryName(path_val, std.heap.page_allocator) catch {
        std.debug.print("Failed to get directory name\n", .{});
        return error.NoDirectoryNameReturned;
    };



    // finds vm file, creates parser and parses the file, creates output file
    const parsingResult = findFilesAndParse(dir, dir_name) catch |err| {
        print("ERROR while parsing files: {}\n", .{err});
        return;
    };

    // distributing the tuple of return values to their respective variables
    var parser = parsingResult.parser;
    // const baseName = parsingResult.baseName;
    const wFile = parsingResult.outputFile;
    const outputFileName = parsingResult.outputFileName;
    const numFiles = parsingResult.numFiles;


    // Initialize a CodeWriter to generate assembly code
    var writer = codeWriterModule.CodeWriter.newCodeWriter(outputFileName);

    const allocator = std.heap.page_allocator;       //move before loop

    // add boot to
    if (numFiles > 1) {
        const bootStrapCode = writer.writeCall( "Sys.init", 0, allocator) catch |err| {
            print("ERROR writing bootstrap code:\n {}\n", .{err});
            return;
        };
        const fullBootCode = std.fmt.allocPrint(allocator, "@256\nD=A\n@SP\nM=D\n{s}", .{bootStrapCode}) catch |err| {
            print("ERROR writing bootstrap code:\n {}\n", .{err});
            return;
        };
        const cFBC: []const u8 = fullBootCode;
        const bootBytesWritten = wFile.write(cFBC) catch | err | {
            print("ERROR while writing bootstrap code to file: {}\n", .{err});
            return;
        };
        _ = bootBytesWritten;
    }

    var lineNum: usize = 13; // Line number used for label generation (especially for comparisons)


    // if we are dealing with multi-file function

    var vmCounter: i32 = 0;


    // Process each command in the input file
    while (parser.hasMoreCommands()){
        parser.advance(); // Advance to the next command

        const cmdType = parser.current_command;

        // Assembly instructions for the current command
        const newLines: []const u8 = createNewLines(cmdType,&writer,allocator,&parser, &vmCounter) catch |err| {
            print("Error while creating new lines", .{});
            return err;
        };

        // Write generated assembly code to the output file
        const bytesWritten = wFile.write(newLines) catch |err|{
            print("ERROR while writing to output file: {}\n", .{err});
            return;
        };
        _ = bytesWritten; // Ignore the actual number of bytes written

        // Update line counter based on how many assembly lines were generated
        const lineCount = std.mem.count(u8, newLines, "\n");
        lineNum += lineCount - 1;  // subtract 1 because one "line" might just be a comment or blank

        // Free dynamically allocated memory if needed
        if (cmdType == .eq or cmdType == .gt or cmdType == .lt or cmdType == .eq or cmdType == .push or cmdType == .pop){
            allocator.free(newLines);
        }
    }

    // Success message
    print("\nWrote successfully to file.\n", .{});
    wFile.close(); // Explicitly close the output file
}
