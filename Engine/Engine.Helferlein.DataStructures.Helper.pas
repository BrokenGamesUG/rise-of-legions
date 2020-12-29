unit Engine.Helferlein.DataStructures.Helper;

interface

uses
  Engine.Math,
  Engine.Math.Collision3D,
  Engine.Helferlein,
  Engine.Vertex,
  Engine.Helferlein.DataStructures,
  /// ///////////////////////////
  Math;

type

  /// <summary> A node of k-d tree. Nothing interesting for the user. </summary>
  TkdTreeNodeHelper<T : class> = class(Engine.Helferlein.DataStructures.TkdTreeNode<T>)
    public
      procedure RenderDebug;
  end;

  /// <summary> A k-dimensional tree for spatial splitting. </summary>
  TkdTree<T : class> = class(Engine.Helferlein.DataStructures.TkdTree<T>)
    public
      procedure RenderDebug;
  end;

implementation


{ TkdTreeNode<T> }

procedure TkdTree<T>.RenderDebug;
begin
  TkdTreeNodeHelper<T>(FRoot).RenderDebug;
end;

{ TkdTreeNodeHelper<T> }

procedure TkdTreeNodeHelper<T>.RenderDebug;
begin
  if not IsLeaf then
  begin
    LinePool.AddPlane(SplittingPlane, RColor.RGB_ARRAY[FSplitDimension]);
    TkdTreeNodeHelper<T>(FPositiveChildren).RenderDebug;
    TkdTreeNodeHelper<T>(FNegativeChildren).RenderDebug;
  end;
end;

end.
