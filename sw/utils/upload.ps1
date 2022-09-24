$port = new-object System.IO.Ports.SerialPort COM3, 9600, None, 8, One;

$port.Open();

$wrcmd = [System.Convert]::ToChar(0x31);

$port.Write($wrcmd);

$pkg = New-Object byte[] 65536;

$sw  = [System.IO.File]::ReadAllBytes($args[0]);

$sw.CopyTo($pkg,0);

Write-Host "sending data ..."

$port.Write($pkg, 0, $pkg.Count);

Write-Host "OK"

while($port.IsOpen) {
	$data = $port.ReadLine();
	Write-Host $data;
}

$port.Close();