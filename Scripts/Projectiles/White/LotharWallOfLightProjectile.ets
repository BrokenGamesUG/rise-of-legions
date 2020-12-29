{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 30 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TVertexQuadComponent.Create(Entity, 'Effects\Textures\LensFlare.tga', 7.0, 3.5)
      .ScreenSpace()
      .Additive()
      .Color($FFFEFF98);

    TVertexQuadComponent.Create(Entity, 'Effects\Textures\WhiteShield.png', 0.7, 0.7)
      .ScreenSpace()
      .Additive();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\LightTrace.tga')
      .Color($80FFFFFF)
      .Width(0.2)
      .SamplingDistance(0.5)
      .FadeLength(2.0)
      .MaxLength(2.0)
      .TexturePerDistance(4.0)
      .Additive;

    TPointLightComponent.Create(Entity, $5AFEFF98, 3);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustHave([upUnit])
      .MustNotHave([upBase]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
  {$ENDIF}

  // add shield block
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Shieldblock.dws');

  {$IFDEF CLIENT}
    TPositionerSplineComponent.Create(Entity)
      .BothTangents(PI / 16, 0, 1)
      .BindToSubPosition(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.CreateGrouped(Entity, [0], 'event:/card/white/effect/shield_block')
      .TriggerOnFireWarhead();
  {$ENDIF}
end;
