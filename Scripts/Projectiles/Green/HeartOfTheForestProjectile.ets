{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 14 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
var i : integer;
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\GreenLensFlare.tga', 2.8, 1.4)
      .ScreenSpace()
      .Additive()
      .Color($A0FFFFFF);

    for i := 0 to 2 do
    begin
      TPositionerRotationComponent.CreateGrouped(Entity, [1+i])
        .Radius(0.15)
        .RotationSpeed(0, 0, 14 * PI)
        .Phase(i * 0.25);
      TVertexTraceComponent.CreateGrouped(Entity, [1+i])
        .Texture('Effects\Textures\NatureTrace.tga')
        .Color($A0FFFFFF)
        .Width(0.1)
        .SamplingDistance(0.2)
        .FadeLength(2.0)
        .MaxLength(5.0)
        .TexturePerDistance(4.0)
        .FadeWidening(-0.09)
        .Additive
        .IsPiece;
    end;

    TParticleEffectComponent.Create(Entity, '\Green\heart_of_the_forest_projectile_trail.pfx', 4.0)
      .ActivateOnCreate();
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\BlessingStrength.dws');

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .StartTangent(PI / 2, 0, 3)
      .EndTangent(PI / 2, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/green/unit/hearT_of_the_forest/attack_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
