let 
    fn_ReadZipArchive = (
        ZipFile as binary
    ) as table =>

let
    Header = BinaryFormat.Record([
        MiscHeader = BinaryFormat.Binary(14),
        BinarySize = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        FileSize   = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        FileNameLen= BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
        ExtrasLen  = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian)    
    ]),
 
    HeaderChoice = BinaryFormat.Choice(
        BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        each if _ <> 67324752             // not the IsValid number? then return a dummy formatter
            then BinaryFormat.Record([IsValid = false, Filename=null, Content=null])
            else BinaryFormat.Choice(
                    BinaryFormat.Binary(26),      // Header payload - 14+4+4+2+2
                    each BinaryFormat.Record([
                        IsValid  = true,
                        Filename = BinaryFormat.Text(Header(_)[FileNameLen]),
                        Extras   = BinaryFormat.Text(Header(_)[ExtrasLen]),
                        Content  = BinaryFormat.Transform(
                            BinaryFormat.Binary(Header(_)[BinarySize]),
                            (x) => try Binary.Buffer(Binary.Decompress(x, Compression.Deflate)) otherwise null
                        )
                        ]),
                        type binary                   // enable streaming
                )
    ),
 
    ZipFormat = BinaryFormat.List(HeaderChoice, each _[IsValid] = true),
 
    Entries = List.Transform(
        List.RemoveLastN( ZipFormat(ZipFile), 1),
        (e) => [FileName = e[Filename], Content = e[Content] ]
    )
in
    Table.FromRecords(Entries),

    documentation = [
        Documentation.Name =  "fn_ReadZipArchive",
        Documentation.Description = "Takes the zip file list of a file table and returns the content as a table object in Power Query.",
        Documentation.LongDescription = "Takes the zip file list of an archive and returns the content as a table object in Power Query. ",
        Documentation.Category = "Table",
        Documentation.Source = "https://github.com/Auguronomics/PowerBi-code/blob/master/PowerQuery/ExtractZIP.pq"
    ]
in Value.ReplaceType(fn_ReadZipArchive,Value.ReplaceMetadata(Value.Type(fn_ReadZipArchive), documentation) )
