{$INCLUDE 'DropTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitDropData(Entity, False, {@UBL_Tier}2);
  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Black\VoidCauldron');
  Entity.Blackboard.SetValue(eiWelaCount, [GROUP_DROP_SPAWNER], {@UBL_SquadSize}1);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitDropMeta(Entity);

  {$IFDEF CLIENT}
    TWelaEventRedirecter.CreateGrouped(Entity, [GROUP_DROP_SPAWNER])
      .CopyValue(eiWelaRange, [1], [8]);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [8])
     .SetTexture('SpelltargetShootingRange.png')
     .ShowWeaponRange;
    TWelaEventRedirecter.CreateGrouped(Entity, [GROUP_DROP_SPAWNER])
      .CopyValue(eiWelaRange, [2], [9]);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [9])
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitDropEntity(Entity);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
