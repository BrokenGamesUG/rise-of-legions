{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 44 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
var i : integer;
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\BlueLensFlare.tga', 7.0, 7.0)
      .ScreenSpace()
      .Additive();

    TParticleEffectComponent.Create(Entity, '\Blue\bombardier_projectile_trail.pfx', 0.8)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\BlueTrace.tga')
      .Color($A05BA9FF)
      .Width(0.4)
      .SamplingDistance(0.5)
      .FadeLength(5.0)
      .MaxLength(5.0)
      .TexturePerDistance(4.0)
      .Additive;

    TPointLightComponent.Create(Entity, $5A5BA9FF, 4);

    for i := 0 to 2 do
    begin
      TPositionerRotationComponent.CreateGrouped(Entity, [1+i])
        .Radius(0.25)
        .RotationSpeed(0, 0, 14 * PI)
        .Phase(i * 0.25);
      TVertexTraceComponent.CreateGrouped(Entity, [1+i])
        .Texture('Effects\Textures\BlueTrace.tga')
        .Color($A05BA9FF)
        .Width(0.1)
        .SamplingDistance(0.01)
        .FadeLength(3.0)
        .MaxLength(5.0)
        .TexturePerDistance(4.0)
        .Additive
        .IsPiece;
    end;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0])
      .NoTargetChecks();
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWarheadSpottyDamageComponent.CreateGrouped(Entity, [0]);

    TAutoBrainOnDealDamageComponent.CreateGrouped(Entity, [1]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [1])
      .MustHave([upUnit])
      .MustNotHave([upLegendary, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [1]);
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [1], 'Modifiers\Stun.dws');

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(0, 0, 1)
      .BindToSubPosition(BIND_ZONE_WEAPON_MUZZLE, [0, 1]);

    TParticleEffectComponent.CreateGrouped(Entity, [0], '\Blue\blue_projectile_impact.pfx', 0.6)
      .ActivateOnFree
      .FixedOrientationDefault;

    TSoundComponent.Create(Entity, 'event:/card/blue/unit/bombardier/wavegun_impact')
      .TriggerOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetRotationStrong
      .ActivateOnFree;

    TCameraShakerComponent.CreateGrouped(Entity, [])
      .PresetVectorStrong
      .ActivateOnFree;
  {$ENDIF}
end;
