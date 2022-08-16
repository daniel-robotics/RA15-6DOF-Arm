if (( $# == 1 ))
then
  COM=$1
else
  COM=usb
fi
echo "Executing NeXTTool to upload TouchMUX_Test.rxe to device: COM=$COM ..."
 /nxtOSEK2.18/NeXTTool.exe /COM=$COM -download=TouchMUX_Test.rxe
 /nxtOSEK2.18/NeXTTool.exe /COM=$COM -listfiles=TouchMUX_Test.rxe
echo NeXTTool is terminated.
