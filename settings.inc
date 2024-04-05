{$X+} {Extended syntax}
{$I-} {No I/O errors}
{$B+} {Shortcut boolean expressions}
{$G-} {8086 compatibility}
{$R+} {Range checking}
{$M 49152,0,458752} {Limit heap to 448K and stack to 48K, to allow big EXTERNs to run}
{-$define lowmem}
{-$define VGA}
