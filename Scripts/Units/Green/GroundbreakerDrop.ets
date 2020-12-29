{$INCLUDE 'DropTemplate.dws'};

procedure CreateData(Entity : TEntity);
begin
  InitDropData(Entity, False, {@UBL_Tier}3);

  Entity.Blackboard.SetValue(eiWelaUnitPattern, [GROUP_DROP_SPAWNER], 'Units\Green\Groundbreaker');

  Entity.Blackboard.SetValue(eiWelaCount, [GROUP_DROP_SPAWNER], {@UBL_SquadSize}1);
end;

procedure CreateMeta(Entity : TEntity);
begin
  CreateData(Entity);
  InitDropMeta(Entity);

  {$IFDEF CLIENT}
    TWelaEventRedirecter.CreateGrouped(Entity, [GROUP_DROP_SPAWNER])
      .CopyValue(eiWelaRange, [5], [10]);
    TTextureRangeIndicatorComponent.CreateGrouped(Entity, [10])
      .ShowWeaponRange
      .SetTexture('SpelltargetGeneric.png');
  {$ENDIF}
end;

procedure CreateEntity(Entity : TEntity);
begin
  CreateMeta(Entity);
  InitDropEntity(Entity, True);

  {$IFDEF SERVER}
  {$ENDIF}

  {$IFDEF CLIENT}
  {$ENDIF}
end;
