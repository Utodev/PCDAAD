{$X+} {Extended syntax}
{$I-} {No I/O errors}
{$B+} {Shortcut boolean expressions}
{$M 65520, 163840, 655360}
{$define VGA}
{$G-} {8086 compatibility}
{$R+} {Range checking}
{$M 65000,0,196608} {Limit heap to 192K and stack to ~64K, to avoid big EXTERNs to run}