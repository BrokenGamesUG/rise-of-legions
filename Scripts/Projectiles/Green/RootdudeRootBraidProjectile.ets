{$INCLUDE 'Math.dws'};

procedure CreateData(Entity : TEntity);
begin
  Entity.Blackboard.SetValue(eiSpeed, [], 20 / 1000);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);

  {$IFDEF CLIENT}
    TParticleEffectComponent.Create(Entity, '\Green\rootdude_projectile.pfx', 1.0)
      .ActivateOnCreate();

    TVertexTraceComponent.CreateGrouped(Entity, [])
      .Texture('Effects\Textures\RootTrail.tga')
      .Color($FFFFFFFF)
      .Width(0.8)
      .SamplingDistance(0.5)
      .FadeLength(0.5)
      .MaxLength(5.0)
      .TexturePerDistance(4.0)
      .FixedOrientationDefault
      .FixedHeightGround;
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);

  {$IFDEF SERVER}
    TMovementComponent.Create(Entity);
    TBrainProjectileComponent.CreateGrouped(Entity, [0]);
    TWelaTargetConstraintUnitPropertyComponent.CreateGrouped(Entity, [0])
      .MustNotHave([upImmuneToRooted, upImmuneToStateEffects]);
    TWelaEffectInstantComponent.CreateGrouped(Entity, [0]);
    TWelaEffectStatisticsComponent.CreateGrouped(Entity, [0])
      .Name('Root')
      .TriggerOnFire;
  {$ENDIF}

  // add root
  TWarheadApplyScriptComponent.CreateGrouped(Entity, [0], 'Modifiers\Root.dws');

  {$IFDEF CLIENT}
  {$ENDIF}
end;
