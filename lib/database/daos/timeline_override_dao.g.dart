// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_override_dao.dart';

// ignore_for_file: type=lint
mixin _$TimelineOverrideDaoMixin on DatabaseAccessor<AppDatabase> {
  $TripsTable get trips => attachedDatabase.trips;
  $AttractionsTable get attractions => attachedDatabase.attractions;
  $TimelineOverridesTable get timelineOverrides =>
      attachedDatabase.timelineOverrides;
  TimelineOverrideDaoManager get managers => TimelineOverrideDaoManager(this);
}

class TimelineOverrideDaoManager {
  final _$TimelineOverrideDaoMixin _db;
  TimelineOverrideDaoManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db.attachedDatabase, _db.trips);
  $$AttractionsTableTableManager get attractions =>
      $$AttractionsTableTableManager(_db.attachedDatabase, _db.attractions);
  $$TimelineOverridesTableTableManager get timelineOverrides =>
      $$TimelineOverridesTableTableManager(
        _db.attachedDatabase,
        _db.timelineOverrides,
      );
}
