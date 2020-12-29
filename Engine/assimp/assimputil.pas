{ Open Asset Import Library (ASSIMP) Pascal Header

---------------------------------------------------------------------------
Copyright (c) 2012, Steve Hilderbrandt, Necem dot dev at gmx dot net

All rights reserved.

Redistribution and use of this software in source and binary forms,
with or without modification, are permitted provided that the following
conditions are met:

* Redistributions of source code must retain the above
  copyright notice, this list of conditions and the
  following disclaimer.

* Redistributions in binary form must reproduce the above
  copyright notice, this list of conditions and the
  following disclaimer in the documentation and/or other
  materials provided with the distribution.

* Neither the name of Steve Hilderbrandt, nor the names of its
  contributors may be used to endorse or promote products
  derived from this software without specific prior
  written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------
Based on :

Open Asset Import Library (ASSIMP)
Copyright (c) 2006-2010, ASSIMP Development Team assimp.sourceforge.net
3-clause BSD license
}
unit AssimpUtil;

{$I assimpDefines.inc}

{$I compilersetup.inc}

interface

uses LazUTF8,

     {$IFDEF AI_EXTERNAL_MATH_TYPES}{$I aiExternalMathUnits.inc}{$IFEND AI_EXTERNAL_MATH_TYPES}

     AssimpHeader;

function aiIsExtensionSupported(const ext : String) : Boolean; {$IFDEF INLINE}inline;{$ENDIF INLINE}
function aiGetExtensionList : UTF8String; {$IFDEF INLINE}inline;{$ENDIF INLINE}
function aiGetCameraMatrix(aCamera : PAiCamera) : TAiMatrix4x4; {$IFDEF INLINE}inline;{$ENDIF INLINE}

function aiGetMatrialPropertyString(const aProperty : TAiMaterialProperty) : UTF8String; {$IFDEF INLINE}inline;{$ENDIF INLINE}

procedure dumpAiScene(const aScene : TAiScene; complete : Boolean = false);
procedure dumpAiNode(const aNode : TAiNode; complete : Boolean = false);
procedure dumpAiMesh(const aMesh : TAiMesh; complete : Boolean = false);
procedure dumpAiMaterial(const aMaterial : TAiMaterial; complete : Boolean = false);

operator := (const aiStr : TAiString) : UTF8String; {$IFDEF INLINE}inline;{$ENDIF INLINE}
operator := (const utf8 : UTF8String) : TAiString; {$IFDEF INLINE}inline;{$ENDIF INLINE}

implementation

operator := (const aiStr : TAiString) : UTF8String;
var length : LongWord;
begin
  if aiStr.length = 0
    then
      begin
        result := '';
        Exit;
      end;

  length := UTF8Length(@aiStr.data, aiStr.length);

  setLength(result, length);

  Move(aiStr.data[0], result[1], aiStr.length);
end;

operator := (const utf8 : UTF8String) : TAiString;
var p : PChar;
begin
  p := PChar(utf8);

  result.length := Length(p);

  if result.length > 0 then Move(utf8[1], result.data[0], result.length);

  result.data[result.length] := #0;
end;

function aiIsExtensionSupported(const ext : String) : Boolean;
begin
  result := ByteBool(AssimpHeader.aiIsExtensionSupported(PAiChar(ext)));
end;

function aiGetExtensionList : UTF8String;
var szOut : TAiString;
begin
  szOut := '';

  AssimpHeader.aiGetExtensionList(szOut);

  result := szOut;
end;

function aiGetMatrialPropertyString(const aProperty : TAiMaterialProperty) : UTF8String;
var tmp : TAiString;
begin
  with aProperty do
    begin
      tmp := (PAiString(mData - SizeOf(TAiInt)))^;
      tmp.length := mDataLength  - SizeOf(TAiInt);
    end;

  result := tmp;
end;

procedure dumpAiScene(const aScene : TAiScene; complete : Boolean);
var I : Integer;
begin
  with aScene do
    begin
      dumpAiNode(mRootNode^, complete);

      for I := 0 to mNumMeshes - 1 do
        begin
          writeln;
          writeln('mMeshes[',I,']');
          dumpAiMesh(mMeshes[I]^, complete);
        end;

      for I := 0 to mNumMaterials - 1 do
        begin
          writeln;
          writeln('mMaterials[',I,']');
          dumpAiMaterial(mMaterials[I]^, complete);
        end;
    end;
end;

procedure dumpAiNode(const aNode : TAiNode; complete : Boolean);
var I : Integer;
begin
  with aNode do
    begin
      writeln('mName           : ',UTF8String(mName));
      writeln('mTransformation : ','TODO');
      writeln('mParent         : ',{%H-}PtrUInt(mParent));
      writeln('mNumChildren    : ',mNumChildren);
      writeln('mChildren       : ',{%H-}PtrUInt(mChildren));
      writeln('mNumMeshes      : ',mNumMeshes);
      writeln('mMeshes         : ',{%H-}PtrUInt(mMeshes));

      for I := 0 to mNumMeshes - 1 do
        writeln('mMeshes[',I,']      : ',mMeshes[I]);

      if complete
        then
          begin
            for I := 0 to mNumChildren - 1 do
              dumpAiNode(mChildren[I]^);
          end;
    end;
end;

procedure dumpAiMesh(const aMesh : TAiMesh; complete : Boolean);
var I, J : Integer;
begin
  with aMesh do
    begin
      if (mPrimitiveTypes and AI_PRIMITIVETYPE_POINT    )= AI_PRIMITIVETYPE_POINT    then writeln('mPrimitiveTypes  : AI_PRIMITIVETYPE_POINT');
      if (mPrimitiveTypes and AI_PRIMITIVETYPE_LINE     )= AI_PRIMITIVETYPE_LINE     then writeln('mPrimitiveTypes  : AI_PRIMITIVETYPE_LINE');
      if (mPrimitiveTypes and AI_PRIMITIVETYPE_TRIANGLE )= AI_PRIMITIVETYPE_TRIANGLE then writeln('mPrimitiveTypes  : AI_PRIMITIVETYPE_TRIANGLE');
      if (mPrimitiveTypes and AI_PRIMITIVETYPE_POLYGON  )= AI_PRIMITIVETYPE_POLYGON  then writeln('mPrimitiveTypes  : AI_PRIMITIVETYPE_POLYGON');

      writeln('mNumVertices     : ',mNumVertices);
      writeln('mNumFaces        : ',mNumFaces);
      writeln('mVertices        : ',{%H-}PtruInt(mVertices));

      if (mVertices <> nil) and complete
        then
          begin
            for I := 0 to mNumVertices - 1 do
              with mVertices[I] do
                begin
                  writeln('mVertices[',I:3,']   : X ', X:3:6, ' Y ', Y:3:6, ' Z ', Z:3:6);
                end;
          end;

      writeln('mNormals         : ',{%H-}PtruInt(mNormals));

      if (mNormals <> nil) and complete
        then
          begin
            for I := 0 to mNumVertices - 1 do
              with mNormals[I] do
                begin
                  writeln('mNormals[',I:3,']    : X ', X:3:6, ' Y ', Y:3:6, ' Z ', Z:3:6);
                end;
          end;

      writeln('mTangents        : ',{%H-}PtruInt(mTangents));

      if (mTangents <> nil) and complete
        then
          begin
            for I := 0 to mNumVertices - 1 do
              with mTangents[I] do
                begin
                  writeln('mTangents[',I:3,']   : X ', X:3:6, ' Y ', Y:3:6, ' Z ', Z:3:6);
                end;
          end;

      writeln('mBitangents      : ',{%H-}PtruInt(mBitangents));

      if (mBitangents <> nil) and complete
        then
          begin
            for I := 0 to mNumVertices - 1 do
              with mBitangents[I] do
                begin
                  writeln('mBitangents[',I:3,'] : X ', X:3:6, ' Y ', Y:3:6, ' Z ', Z:3:6);
                end;
          end;

      for I := 0 to high(mColors) do
        begin
          if mColors[I] = nil
            then writeln('mColors',I,'         : n/a')
            else
              begin
                if not complete
                  then writeln('mColors',I,'         : available')
                  else
                    begin
                      for J := 0 to mNumVertices - 1 do
                        with mColors[I][J] do
                          writeln('mColors',I,'[',J:3,']     : R ', X:3:6, ' G ', Y:3:6, ' B ', Z:3:6, ' A ', W:3:6);
                    end;
              end;
          end;

      for I := 0 to high(mTextureCoords) do
        begin
          if mTextureCoords[I] = nil
            then writeln('mTextureCoords',I,'  : n/a')
            else
              begin
                if not complete
                  then writeln('mTextureCoords',I,'  : available')
                  else
                    begin
                      for J := 0 to mNumVertices - 1 do
                        with mTextureCoords[I][J] do
                          writeln('mTextureCoords',I,'[',J:3,'] : U ', X:3:6, ' V ', Y:3:6, ' W ', Z:3:6);
                    end;
              end;
          end;

      for I := 0 to High(mNumUVComponents) do
        writeln('mNumUVComponents',I,': ',mNumUVComponents[I]);

      writeln('mFaces           : ',{%H-}PtruInt(mFaces));

      for I := 0 to mNumFaces - 1 do
        with mFaces[I] do
          begin
            writeln('mFaces[',I:2,']       : mNumIndices ', mNumIndices, ' mIndices ', {%H-}PtrUInt(mIndices));

            if mNumIndices > 3 then continue;

            for J := 0 to mNumIndices - 1 do
              writeln('mIndices[',J:2,']     : ', mIndices[J]);
          end;

      writeln('mNumBones        : ',mNumBones);
      writeln('mBones           : ',{%H-}PtruInt(mBones));
      writeln('mMaterialIndex   : ',mMaterialIndex);
      writeln('mName            : ',UTF8String(mName));
      writeln('mNumAnimMeshes   : ',mNumAnimMeshes);
      writeln('mAnimMeshes      : ',{%H-}PtruInt(mAnimMeshes));
    end;
end;

procedure dumpAiMaterial(const aMaterial : TAiMaterial; complete : Boolean);
var I, J : Integer;
begin
  with aMaterial do
    begin
      writeln('mProperties    : ',{%H-}PtruInt(mProperties));
      writeln('mNumProperties : ',mNumProperties);
      writeln('mNumAllocated  : ',mNumAllocated);

      for I := 0 to mNumProperties - 1 do
        begin
          writeln('mProperties[',I,'].mKey        : ',UTF8String(mProperties[I]^.mKey));
          if complete
            then
              begin
                with mProperties[I]^ do
                  begin
                    writeln('mProperties[',I,'].mSemantic   : ',mSemantic);
                    writeln('mProperties[',I,'].mIndex      : ',mIndex);
                    writeln('mProperties[',I,'].mDataLength : ',mDataLength);
                    case mType of
                      AI_PTI_FLOAT    :
                      begin
                        writeln('mProperties[',I,'].mType       : AI_PTI_FLOAT');
                        for J := 0 to (mDataLength div SizeOf(TAiFloat)) - 1 do
                          writeln('mProperties[',I,'].mData[',J,']    : ',PAiFloat(mData + J * SizeOf(TAiFloat))^:4:7);
                      end;
                      AI_PTI_STRING   :
                      begin
                        writeln('mProperties[',I,'].mType       : AI_PTI_STRING');
                        writeln('mProperties[',I,'].mData       : ',aiGetMatrialPropertyString(mProperties[I]^));
                      end;
                      AI_PTI_INTEGER  :
                      begin
                        writeln('mProperties[',I,'].mType       : AI_PTI_INTEGER');
                        for J := 0 to (mDataLength div SizeOf(TAiInt)) - 1 do
                          writeln('mProperties[',I,'].mData       : ',PAiInt(mData + J * SizeOf(TAiInt))^);
                      end;
                      AI_PTI_BUFFER   :
                      begin
                        writeln('mProperties[',I,'].mType       : AI_PTI_BUFFER');
                        writeln('mProperties[',I,'].mData       : ',{%H-}PtruInt(mData));
                      end;
                    end;
                  end;
              end;
        end;
    end;
end;

{$IFNDEF AI_EXTERNAL_MATH_TYPES}
function aiGetCameraMatrix(aCamera : PAiCamera) : TAiMatrix4x4;
var x, y, z : TAiVector3D;
begin
  with aCamera^ do
    begin
      //TODO
      z := mLookAt;     //zaxis.Normalize();
      y := mUp;         //yaxis.Normalize();
      //x := mUp^mLookAt; xaxis.Normalize();

      //result.a4 := -(x * mPosition);
      //result.b4 := -(y * mPosition);
      //result.c4 := -(z * mPosition);

      result.a1 := x.x;
      result.a2 := x.y;
      result.a3 := x.z;

      result.b1 := y.x;
      result.b2 := y.y;
      result.b3 := y.z;

      result.c1 := z.x;
      result.c2 := z.y;
      result.c3 := z.z;

      result.d1 := 0;
      result.d2 := 0;
      result.d3 := 0;
      result.d4 := 1;
    end;
end;
{$ELSE}
{$I aiUtilExternalMath.inc}
{$IFEND AI_EXTERNAL_MATH_TYPES}

end.

