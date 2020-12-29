{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 3 / 1000);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [0], 'Units\Golems\GolemsSmallMeleeGolem');
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TMeshComponent.Create(Entity, 'Units\Colorless\BigMeleeGolem\Projectile\Stone.xml')
      .ApplyLegacySizeFactor;

    TParticleEffectComponent.Create(Entity, '\Colorless\splinter_projectile_trail.pfx', 1.0)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\StoneTrace.tga')
      .Color($80FFFFFF)
      .Width(0.65)
      .SamplingDistance(0.25)
      .FadeLength(3.0)
      .MaxLength(4.0)
      .TexturePerDistance(4.0);
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaEffectFactoryComponent.CreateGrouped(Entity, [0])
      .PassCardValues;
  {$ENDIF}

  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\LegendarySpawn.dws')
    .PassIntValue(500)
    .ApplyToProducedUnits();

  {$IFDEF CLIENT}
    TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Drop.dws')
      .ApplyToProducedUnits();

    TOrienterAutoRotationComponent.Create(Entity)
      .SetSpeed(RVector3.Create(0.006, 0*0.0051, 0*0.0084));

    TPositionerSplineComponent.Create(Entity)
      .OrientStartWithTarget
      .StartTangent(PI / 2.4, 0, 4)
      .EndTangent(PI / 1.8, 0, 2)
      .BindToSubPosition(BIND_ZONE_CENTER, [0, 1]);

    TSoundComponent.Create(Entity, 'event:/card/colorless/unit/big_melee_golem/splinter_impact')
      .TriggerOnFree;
  {$ENDIF}
end;
