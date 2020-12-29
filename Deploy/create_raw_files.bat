echo Do you want to make a full rebuild?
set /p full_rebuild="y/n: "

echo.
if "%full_rebuild%" == "n" (
	echo Do you want to renew the precompiled textures?
	set /p textures="y/n: "
) ELSE (
	set textures=y
)
if "%textures%" == "y" (
	Tools\EngineTextureCompiler.exe "\..\..\Graphics" "\..\..\Maps" mhLoad="Graphics\GUI\Shared\CardIcons" mhLoad="Graphics\GUI\Shared\WithMipMaps"
)

echo.
if "%full_rebuild%" == "n" (
	echo Do you want to renew the precompiled meshes?
	set /p meshes="y/n: "
) ELSE (
	set meshes=y
)
if "%meshes%" == "y" (
	Tools\EngineMeshCompiler.exe "\..\..\Graphics"
)

echo.
if "%full_rebuild%" == "n" (
	echo Do you want to renew the preloader cache?
	set /p preloader="y/n: "
) ELSE (
	set preloader=y
)
if "%preloader%" == "y" (
	Tools\RoLTools.exe "buildpreloadercache" "\..\..\"
)

echo.
echo ========
echo finished
pause