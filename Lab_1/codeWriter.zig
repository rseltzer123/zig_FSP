pub const CodeWriter = struct {
    output: []u8,         // or a file handle if writing directly
    file_name: []const u8,  // For naming static variables: "FileName.i"
    label_counter: usize, // To generate unique labels in comparisons
};