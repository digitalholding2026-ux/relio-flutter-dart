// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotionsTable extends Notions with TableInfo<$NotionsTable, NotionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainIdMeta = const VerificationMeta(
    'domainId',
  );
  @override
  late final GeneratedColumn<String> domainId = GeneratedColumn<String>(
    'domain_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelIdMeta = const VerificationMeta(
    'levelId',
  );
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
    'level_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<NotionLifecycle, String>
  lifecycle = GeneratedColumn<String>(
    'lifecycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant('draft'),
  ).withConverter<NotionLifecycle>($NotionsTable.$converterlifecycle);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($NotionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($NotionsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    description,
    domainId,
    levelId,
    lifecycle,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notions';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('domain_id')) {
      context.handle(
        _domainIdMeta,
        domainId.isAcceptableOrUnknown(data['domain_id']!, _domainIdMeta),
      );
    }
    if (data.containsKey('level_id')) {
      context.handle(
        _levelIdMeta,
        levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      domainId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain_id'],
      ),
      levelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level_id'],
      ),
      lifecycle: $NotionsTable.$converterlifecycle.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}lifecycle'],
        )!,
      ),
      createdAt: $NotionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $NotionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $NotionsTable createAlias(String alias) {
    return $NotionsTable(attachedDatabase, alias);
  }

  static TypeConverter<NotionLifecycle, String> $converterlifecycle =
      const NotionLifecycleConverter();
  static TypeConverter<DateTime, String> $convertercreatedAt =
      const DateTimeUtcConverter();
  static TypeConverter<DateTime, String> $converterupdatedAt =
      const DateTimeUtcConverter();
}

class NotionRow extends DataClass implements Insertable<NotionRow> {
  /// Identifiant stable, choisi par le domaine. Jamais régénéré.
  final String id;
  final String label;
  final String? description;
  final String? domainId;
  final String? levelId;

  /// État éditorial (draft / published / archived) — jamais la maîtrise.
  final NotionLifecycle lifecycle;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NotionRow({
    required this.id,
    required this.label,
    this.description,
    this.domainId,
    this.levelId,
    required this.lifecycle,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || domainId != null) {
      map['domain_id'] = Variable<String>(domainId);
    }
    if (!nullToAbsent || levelId != null) {
      map['level_id'] = Variable<String>(levelId);
    }
    {
      map['lifecycle'] = Variable<String>(
        $NotionsTable.$converterlifecycle.toSql(lifecycle),
      );
    }
    {
      map['created_at'] = Variable<String>(
        $NotionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<String>(
        $NotionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  NotionsCompanion toCompanion(bool nullToAbsent) {
    return NotionsCompanion(
      id: Value(id),
      label: Value(label),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      domainId: domainId == null && nullToAbsent
          ? const Value.absent()
          : Value(domainId),
      levelId: levelId == null && nullToAbsent
          ? const Value.absent()
          : Value(levelId),
      lifecycle: Value(lifecycle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotionRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      description: serializer.fromJson<String?>(json['description']),
      domainId: serializer.fromJson<String?>(json['domainId']),
      levelId: serializer.fromJson<String?>(json['levelId']),
      lifecycle: serializer.fromJson<NotionLifecycle>(json['lifecycle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'description': serializer.toJson<String?>(description),
      'domainId': serializer.toJson<String?>(domainId),
      'levelId': serializer.toJson<String?>(levelId),
      'lifecycle': serializer.toJson<NotionLifecycle>(lifecycle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NotionRow copyWith({
    String? id,
    String? label,
    Value<String?> description = const Value.absent(),
    Value<String?> domainId = const Value.absent(),
    Value<String?> levelId = const Value.absent(),
    NotionLifecycle? lifecycle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NotionRow(
    id: id ?? this.id,
    label: label ?? this.label,
    description: description.present ? description.value : this.description,
    domainId: domainId.present ? domainId.value : this.domainId,
    levelId: levelId.present ? levelId.value : this.levelId,
    lifecycle: lifecycle ?? this.lifecycle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NotionRow copyWithCompanion(NotionsCompanion data) {
    return NotionRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      description: data.description.present
          ? data.description.value
          : this.description,
      domainId: data.domainId.present ? data.domainId.value : this.domainId,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      lifecycle: data.lifecycle.present ? data.lifecycle.value : this.lifecycle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotionRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('domainId: $domainId, ')
          ..write('levelId: $levelId, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    description,
    domainId,
    levelId,
    lifecycle,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotionRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.description == this.description &&
          other.domainId == this.domainId &&
          other.levelId == this.levelId &&
          other.lifecycle == this.lifecycle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotionsCompanion extends UpdateCompanion<NotionRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String?> description;
  final Value<String?> domainId;
  final Value<String?> levelId;
  final Value<NotionLifecycle> lifecycle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NotionsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.description = const Value.absent(),
    this.domainId = const Value.absent(),
    this.levelId = const Value.absent(),
    this.lifecycle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotionsCompanion.insert({
    required String id,
    required String label,
    this.description = const Value.absent(),
    this.domainId = const Value.absent(),
    this.levelId = const Value.absent(),
    this.lifecycle = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NotionRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? description,
    Expression<String>? domainId,
    Expression<String>? levelId,
    Expression<String>? lifecycle,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (domainId != null) 'domain_id': domainId,
      if (levelId != null) 'level_id': levelId,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotionsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String?>? description,
    Value<String?>? domainId,
    Value<String?>? levelId,
    Value<NotionLifecycle>? lifecycle,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return NotionsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      domainId: domainId ?? this.domainId,
      levelId: levelId ?? this.levelId,
      lifecycle: lifecycle ?? this.lifecycle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (domainId.present) {
      map['domain_id'] = Variable<String>(domainId.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (lifecycle.present) {
      map['lifecycle'] = Variable<String>(
        $NotionsTable.$converterlifecycle.toSql(lifecycle.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $NotionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $NotionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotionsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('domainId: $domainId, ')
          ..write('levelId: $levelId, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MathDomainsTable extends MathDomains
    with TableInfo<$MathDomainsTable, MathDomainRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MathDomainsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'math_domains';
  @override
  VerificationContext validateIntegrity(
    Insertable<MathDomainRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MathDomainRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MathDomainRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $MathDomainsTable createAlias(String alias) {
    return $MathDomainsTable(attachedDatabase, alias);
  }
}

class MathDomainRow extends DataClass implements Insertable<MathDomainRow> {
  final String id;
  final String label;
  const MathDomainRow({required this.id, required this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    return map;
  }

  MathDomainsCompanion toCompanion(bool nullToAbsent) {
    return MathDomainsCompanion(id: Value(id), label: Value(label));
  }

  factory MathDomainRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MathDomainRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
    };
  }

  MathDomainRow copyWith({String? id, String? label}) =>
      MathDomainRow(id: id ?? this.id, label: label ?? this.label);
  MathDomainRow copyWithCompanion(MathDomainsCompanion data) {
    return MathDomainRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MathDomainRow(')
          ..write('id: $id, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MathDomainRow &&
          other.id == this.id &&
          other.label == this.label);
}

class MathDomainsCompanion extends UpdateCompanion<MathDomainRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<int> rowid;
  const MathDomainsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MathDomainsCompanion.insert({
    required String id,
    required String label,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label);
  static Insertable<MathDomainRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MathDomainsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return MathDomainsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MathDomainsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotionLevelsTable extends NotionLevels
    with TableInfo<$NotionLevelsTable, NotionLevelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotionLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notion_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotionLevelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotionLevelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotionLevelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $NotionLevelsTable createAlias(String alias) {
    return $NotionLevelsTable(attachedDatabase, alias);
  }
}

class NotionLevelRow extends DataClass implements Insertable<NotionLevelRow> {
  final String id;
  final String label;
  final int sortOrder;
  const NotionLevelRow({
    required this.id,
    required this.label,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  NotionLevelsCompanion toCompanion(bool nullToAbsent) {
    return NotionLevelsCompanion(
      id: Value(id),
      label: Value(label),
      sortOrder: Value(sortOrder),
    );
  }

  factory NotionLevelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotionLevelRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  NotionLevelRow copyWith({String? id, String? label, int? sortOrder}) =>
      NotionLevelRow(
        id: id ?? this.id,
        label: label ?? this.label,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  NotionLevelRow copyWithCompanion(NotionLevelsCompanion data) {
    return NotionLevelRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotionLevelRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotionLevelRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.sortOrder == this.sortOrder);
}

class NotionLevelsCompanion extends UpdateCompanion<NotionLevelRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const NotionLevelsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotionLevelsCompanion.insert({
    required String id,
    required String label,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       sortOrder = Value(sortOrder);
  static Insertable<NotionLevelRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotionLevelsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return NotionLevelsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotionLevelsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotionPrerequisitesTable extends NotionPrerequisites
    with TableInfo<$NotionPrerequisitesTable, NotionPrerequisiteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotionPrerequisitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _prerequisiteIdMeta = const VerificationMeta(
    'prerequisiteId',
  );
  @override
  late final GeneratedColumn<String> prerequisiteId = GeneratedColumn<String>(
    'prerequisite_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notionIdMeta = const VerificationMeta(
    'notionId',
  );
  @override
  late final GeneratedColumn<String> notionId = GeneratedColumn<String>(
    'notion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [prerequisiteId, notionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notion_prerequisites';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotionPrerequisiteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prerequisite_id')) {
      context.handle(
        _prerequisiteIdMeta,
        prerequisiteId.isAcceptableOrUnknown(
          data['prerequisite_id']!,
          _prerequisiteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prerequisiteIdMeta);
    }
    if (data.containsKey('notion_id')) {
      context.handle(
        _notionIdMeta,
        notionId.isAcceptableOrUnknown(data['notion_id']!, _notionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {prerequisiteId, notionId};
  @override
  NotionPrerequisiteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotionPrerequisiteRow(
      prerequisiteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prerequisite_id'],
      )!,
      notionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notion_id'],
      )!,
    );
  }

  @override
  $NotionPrerequisitesTable createAlias(String alias) {
    return $NotionPrerequisitesTable(attachedDatabase, alias);
  }
}

class NotionPrerequisiteRow extends DataClass
    implements Insertable<NotionPrerequisiteRow> {
  final String prerequisiteId;
  final String notionId;
  const NotionPrerequisiteRow({
    required this.prerequisiteId,
    required this.notionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prerequisite_id'] = Variable<String>(prerequisiteId);
    map['notion_id'] = Variable<String>(notionId);
    return map;
  }

  NotionPrerequisitesCompanion toCompanion(bool nullToAbsent) {
    return NotionPrerequisitesCompanion(
      prerequisiteId: Value(prerequisiteId),
      notionId: Value(notionId),
    );
  }

  factory NotionPrerequisiteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotionPrerequisiteRow(
      prerequisiteId: serializer.fromJson<String>(json['prerequisiteId']),
      notionId: serializer.fromJson<String>(json['notionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prerequisiteId': serializer.toJson<String>(prerequisiteId),
      'notionId': serializer.toJson<String>(notionId),
    };
  }

  NotionPrerequisiteRow copyWith({String? prerequisiteId, String? notionId}) =>
      NotionPrerequisiteRow(
        prerequisiteId: prerequisiteId ?? this.prerequisiteId,
        notionId: notionId ?? this.notionId,
      );
  NotionPrerequisiteRow copyWithCompanion(NotionPrerequisitesCompanion data) {
    return NotionPrerequisiteRow(
      prerequisiteId: data.prerequisiteId.present
          ? data.prerequisiteId.value
          : this.prerequisiteId,
      notionId: data.notionId.present ? data.notionId.value : this.notionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotionPrerequisiteRow(')
          ..write('prerequisiteId: $prerequisiteId, ')
          ..write('notionId: $notionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(prerequisiteId, notionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotionPrerequisiteRow &&
          other.prerequisiteId == this.prerequisiteId &&
          other.notionId == this.notionId);
}

class NotionPrerequisitesCompanion
    extends UpdateCompanion<NotionPrerequisiteRow> {
  final Value<String> prerequisiteId;
  final Value<String> notionId;
  final Value<int> rowid;
  const NotionPrerequisitesCompanion({
    this.prerequisiteId = const Value.absent(),
    this.notionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotionPrerequisitesCompanion.insert({
    required String prerequisiteId,
    required String notionId,
    this.rowid = const Value.absent(),
  }) : prerequisiteId = Value(prerequisiteId),
       notionId = Value(notionId);
  static Insertable<NotionPrerequisiteRow> custom({
    Expression<String>? prerequisiteId,
    Expression<String>? notionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (prerequisiteId != null) 'prerequisite_id': prerequisiteId,
      if (notionId != null) 'notion_id': notionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotionPrerequisitesCompanion copyWith({
    Value<String>? prerequisiteId,
    Value<String>? notionId,
    Value<int>? rowid,
  }) {
    return NotionPrerequisitesCompanion(
      prerequisiteId: prerequisiteId ?? this.prerequisiteId,
      notionId: notionId ?? this.notionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prerequisiteId.present) {
      map['prerequisite_id'] = Variable<String>(prerequisiteId.value);
    }
    if (notionId.present) {
      map['notion_id'] = Variable<String>(notionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotionPrerequisitesCompanion(')
          ..write('prerequisiteId: $prerequisiteId, ')
          ..write('notionId: $notionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningEventsTable extends LearningEvents
    with TableInfo<$LearningEventsTable, LearningEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> occurredAt =
      GeneratedColumn<String>(
        'occurred_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LearningEventsTable.$converteroccurredAt);
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant('{}'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> recordedAt =
      GeneratedColumn<String>(
        'recorded_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LearningEventsTable.$converterrecordedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    occurredAt,
    contextJson,
    metadataJson,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      occurredAt: $LearningEventsTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}occurred_at'],
        )!,
      ),
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      recordedAt: $LearningEventsTable.$converterrecordedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recorded_at'],
        )!,
      ),
    );
  }

  @override
  $LearningEventsTable createAlias(String alias) {
    return $LearningEventsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converteroccurredAt =
      const DateTimeUtcConverter();
  static TypeConverter<DateTime, String> $converterrecordedAt =
      const DateTimeUtcConverter();
}

class LearningEventRow extends DataClass
    implements Insertable<LearningEventRow> {
  final String id;

  /// Type d'événement (ex. « exercise_attempt »). Indexé pour les filtres.
  final String type;
  final DateTime occurredAt;

  /// Contexte de l'activité, sérialisé en JSON.
  final String? contextJson;

  /// Métadonnées libres propres au type d'événement, sérialisées en JSON.
  ///
  /// Permet d'ajouter des faits sans migration de table.
  final String metadataJson;

  /// Date d'enregistrement en base (pour l'audit et le tri).
  final DateTime recordedAt;
  const LearningEventRow({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.contextJson,
    required this.metadataJson,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    {
      map['occurred_at'] = Variable<String>(
        $LearningEventsTable.$converteroccurredAt.toSql(occurredAt),
      );
    }
    if (!nullToAbsent || contextJson != null) {
      map['context_json'] = Variable<String>(contextJson);
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    {
      map['recorded_at'] = Variable<String>(
        $LearningEventsTable.$converterrecordedAt.toSql(recordedAt),
      );
    }
    return map;
  }

  LearningEventsCompanion toCompanion(bool nullToAbsent) {
    return LearningEventsCompanion(
      id: Value(id),
      type: Value(type),
      occurredAt: Value(occurredAt),
      contextJson: contextJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contextJson),
      metadataJson: Value(metadataJson),
      recordedAt: Value(recordedAt),
    );
  }

  factory LearningEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningEventRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      contextJson: serializer.fromJson<String?>(json['contextJson']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'contextJson': serializer.toJson<String?>(contextJson),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  LearningEventRow copyWith({
    String? id,
    String? type,
    DateTime? occurredAt,
    Value<String?> contextJson = const Value.absent(),
    String? metadataJson,
    DateTime? recordedAt,
  }) => LearningEventRow(
    id: id ?? this.id,
    type: type ?? this.type,
    occurredAt: occurredAt ?? this.occurredAt,
    contextJson: contextJson.present ? contextJson.value : this.contextJson,
    metadataJson: metadataJson ?? this.metadataJson,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  LearningEventRow copyWithCompanion(LearningEventsCompanion data) {
    return LearningEventRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningEventRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('contextJson: $contextJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, occurredAt, contextJson, metadataJson, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningEventRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.occurredAt == this.occurredAt &&
          other.contextJson == this.contextJson &&
          other.metadataJson == this.metadataJson &&
          other.recordedAt == this.recordedAt);
}

class LearningEventsCompanion extends UpdateCompanion<LearningEventRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<DateTime> occurredAt;
  final Value<String?> contextJson;
  final Value<String> metadataJson;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const LearningEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningEventsCompanion.insert({
    required String id,
    required String type,
    required DateTime occurredAt,
    this.contextJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       occurredAt = Value(occurredAt),
       recordedAt = Value(recordedAt);
  static Insertable<LearningEventRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? occurredAt,
    Expression<String>? contextJson,
    Expression<String>? metadataJson,
    Expression<String>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (contextJson != null) 'context_json': contextJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<DateTime>? occurredAt,
    Value<String?>? contextJson,
    Value<String>? metadataJson,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return LearningEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      contextJson: contextJson ?? this.contextJson,
      metadataJson: metadataJson ?? this.metadataJson,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(
        $LearningEventsTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<String>(
        $LearningEventsTable.$converterrecordedAt.toSql(recordedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('contextJson: $contextJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventNotionsTable extends EventNotions
    with TableInfo<$EventNotionsTable, EventNotionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventNotionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learning_events (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _notionIdMeta = const VerificationMeta(
    'notionId',
  );
  @override
  late final GeneratedColumn<String> notionId = GeneratedColumn<String>(
    'notion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, notionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_notions';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventNotionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('notion_id')) {
      context.handle(
        _notionIdMeta,
        notionId.isAcceptableOrUnknown(data['notion_id']!, _notionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, notionId};
  @override
  EventNotionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventNotionRow(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      notionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notion_id'],
      )!,
    );
  }

  @override
  $EventNotionsTable createAlias(String alias) {
    return $EventNotionsTable(attachedDatabase, alias);
  }
}

class EventNotionRow extends DataClass implements Insertable<EventNotionRow> {
  final String eventId;
  final String notionId;
  const EventNotionRow({required this.eventId, required this.notionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['notion_id'] = Variable<String>(notionId);
    return map;
  }

  EventNotionsCompanion toCompanion(bool nullToAbsent) {
    return EventNotionsCompanion(
      eventId: Value(eventId),
      notionId: Value(notionId),
    );
  }

  factory EventNotionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventNotionRow(
      eventId: serializer.fromJson<String>(json['eventId']),
      notionId: serializer.fromJson<String>(json['notionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'notionId': serializer.toJson<String>(notionId),
    };
  }

  EventNotionRow copyWith({String? eventId, String? notionId}) =>
      EventNotionRow(
        eventId: eventId ?? this.eventId,
        notionId: notionId ?? this.notionId,
      );
  EventNotionRow copyWithCompanion(EventNotionsCompanion data) {
    return EventNotionRow(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      notionId: data.notionId.present ? data.notionId.value : this.notionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventNotionRow(')
          ..write('eventId: $eventId, ')
          ..write('notionId: $notionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, notionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventNotionRow &&
          other.eventId == this.eventId &&
          other.notionId == this.notionId);
}

class EventNotionsCompanion extends UpdateCompanion<EventNotionRow> {
  final Value<String> eventId;
  final Value<String> notionId;
  final Value<int> rowid;
  const EventNotionsCompanion({
    this.eventId = const Value.absent(),
    this.notionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventNotionsCompanion.insert({
    required String eventId,
    required String notionId,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       notionId = Value(notionId);
  static Insertable<EventNotionRow> custom({
    Expression<String>? eventId,
    Expression<String>? notionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (notionId != null) 'notion_id': notionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventNotionsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? notionId,
    Value<int>? rowid,
  }) {
    return EventNotionsCompanion(
      eventId: eventId ?? this.eventId,
      notionId: notionId ?? this.notionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (notionId.present) {
      map['notion_id'] = Variable<String>(notionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventNotionsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('notionId: $notionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseAttemptsTable extends ExerciseAttempts
    with TableInfo<$ExerciseAttemptsTable, ExerciseAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learning_events (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> startedAt =
      GeneratedColumn<String>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ExerciseAttemptsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> submittedAt =
      GeneratedColumn<String>(
        'submitted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ExerciseAttemptsTable.$convertersubmittedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<AnswerOutcome, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant('notEvaluated'),
      ).withConverter<AnswerOutcome>($ExerciseAttemptsTable.$converteroutcome);
  static const VerificationMeta _answerIdMeta = const VerificationMeta(
    'answerId',
  );
  @override
  late final GeneratedColumn<String> answerId = GeneratedColumn<String>(
    'answer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerRawMeta = const VerificationMeta(
    'answerRaw',
  );
  @override
  late final GeneratedColumn<String> answerRaw = GeneratedColumn<String>(
    'answer_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerNormalizedMeta = const VerificationMeta(
    'answerNormalized',
  );
  @override
  late final GeneratedColumn<String> answerNormalized = GeneratedColumn<String>(
    'answer_normalized',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerEmptyMeta = const VerificationMeta(
    'answerEmpty',
  );
  @override
  late final GeneratedColumn<bool> answerEmpty = GeneratedColumn<bool>(
    'answer_empty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("answer_empty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    exerciseId,
    startedAt,
    submittedAt,
    outcome,
    answerId,
    answerRaw,
    answerNormalized,
    answerEmpty,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseAttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('answer_id')) {
      context.handle(
        _answerIdMeta,
        answerId.isAcceptableOrUnknown(data['answer_id']!, _answerIdMeta),
      );
    }
    if (data.containsKey('answer_raw')) {
      context.handle(
        _answerRawMeta,
        answerRaw.isAcceptableOrUnknown(data['answer_raw']!, _answerRawMeta),
      );
    }
    if (data.containsKey('answer_normalized')) {
      context.handle(
        _answerNormalizedMeta,
        answerNormalized.isAcceptableOrUnknown(
          data['answer_normalized']!,
          _answerNormalizedMeta,
        ),
      );
    }
    if (data.containsKey('answer_empty')) {
      context.handle(
        _answerEmptyMeta,
        answerEmpty.isAcceptableOrUnknown(
          data['answer_empty']!,
          _answerEmptyMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  ExerciseAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseAttemptRow(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      startedAt: $ExerciseAttemptsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      submittedAt: $ExerciseAttemptsTable.$convertersubmittedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}submitted_at'],
        ),
      ),
      outcome: $ExerciseAttemptsTable.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        )!,
      ),
      answerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_id'],
      ),
      answerRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_raw'],
      ),
      answerNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_normalized'],
      ),
      answerEmpty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}answer_empty'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
    );
  }

  @override
  $ExerciseAttemptsTable createAlias(String alias) {
    return $ExerciseAttemptsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterstartedAt =
      const DateTimeUtcConverter();
  static TypeConverter<DateTime, String> $convertersubmittedAt =
      const DateTimeUtcConverter();
  static TypeConverter<DateTime?, String?> $convertersubmittedAtn =
      NullAwareTypeConverter.wrap($convertersubmittedAt);
  static TypeConverter<AnswerOutcome, String> $converteroutcome =
      const AnswerOutcomeConverter();
}

class ExerciseAttemptRow extends DataClass
    implements Insertable<ExerciseAttemptRow> {
  final String eventId;
  final String exerciseId;
  final DateTime startedAt;
  final DateTime? submittedAt;

  /// Résultat OBSERVABLE : correct / incorrect / notEvaluated / abandoned.
  /// Aucune valeur de maîtrise ici.
  ///
  /// La valeur par défaut est `notEvaluated` : en cas de valeur absente ou
  /// illisible, on ne suppose JAMAIS qu'une réponse était fausse.
  final AnswerOutcome outcome;
  final String? answerId;
  final String? answerRaw;
  final String? answerNormalized;
  final bool answerEmpty;
  final int? durationMs;
  const ExerciseAttemptRow({
    required this.eventId,
    required this.exerciseId,
    required this.startedAt,
    this.submittedAt,
    required this.outcome,
    this.answerId,
    this.answerRaw,
    this.answerNormalized,
    required this.answerEmpty,
    this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['exercise_id'] = Variable<String>(exerciseId);
    {
      map['started_at'] = Variable<String>(
        $ExerciseAttemptsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<String>(
        $ExerciseAttemptsTable.$convertersubmittedAtn.toSql(submittedAt),
      );
    }
    {
      map['outcome'] = Variable<String>(
        $ExerciseAttemptsTable.$converteroutcome.toSql(outcome),
      );
    }
    if (!nullToAbsent || answerId != null) {
      map['answer_id'] = Variable<String>(answerId);
    }
    if (!nullToAbsent || answerRaw != null) {
      map['answer_raw'] = Variable<String>(answerRaw);
    }
    if (!nullToAbsent || answerNormalized != null) {
      map['answer_normalized'] = Variable<String>(answerNormalized);
    }
    map['answer_empty'] = Variable<bool>(answerEmpty);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    return map;
  }

  ExerciseAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseAttemptsCompanion(
      eventId: Value(eventId),
      exerciseId: Value(exerciseId),
      startedAt: Value(startedAt),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      outcome: Value(outcome),
      answerId: answerId == null && nullToAbsent
          ? const Value.absent()
          : Value(answerId),
      answerRaw: answerRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(answerRaw),
      answerNormalized: answerNormalized == null && nullToAbsent
          ? const Value.absent()
          : Value(answerNormalized),
      answerEmpty: Value(answerEmpty),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
    );
  }

  factory ExerciseAttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseAttemptRow(
      eventId: serializer.fromJson<String>(json['eventId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      submittedAt: serializer.fromJson<DateTime?>(json['submittedAt']),
      outcome: serializer.fromJson<AnswerOutcome>(json['outcome']),
      answerId: serializer.fromJson<String?>(json['answerId']),
      answerRaw: serializer.fromJson<String?>(json['answerRaw']),
      answerNormalized: serializer.fromJson<String?>(json['answerNormalized']),
      answerEmpty: serializer.fromJson<bool>(json['answerEmpty']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'submittedAt': serializer.toJson<DateTime?>(submittedAt),
      'outcome': serializer.toJson<AnswerOutcome>(outcome),
      'answerId': serializer.toJson<String?>(answerId),
      'answerRaw': serializer.toJson<String?>(answerRaw),
      'answerNormalized': serializer.toJson<String?>(answerNormalized),
      'answerEmpty': serializer.toJson<bool>(answerEmpty),
      'durationMs': serializer.toJson<int?>(durationMs),
    };
  }

  ExerciseAttemptRow copyWith({
    String? eventId,
    String? exerciseId,
    DateTime? startedAt,
    Value<DateTime?> submittedAt = const Value.absent(),
    AnswerOutcome? outcome,
    Value<String?> answerId = const Value.absent(),
    Value<String?> answerRaw = const Value.absent(),
    Value<String?> answerNormalized = const Value.absent(),
    bool? answerEmpty,
    Value<int?> durationMs = const Value.absent(),
  }) => ExerciseAttemptRow(
    eventId: eventId ?? this.eventId,
    exerciseId: exerciseId ?? this.exerciseId,
    startedAt: startedAt ?? this.startedAt,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    outcome: outcome ?? this.outcome,
    answerId: answerId.present ? answerId.value : this.answerId,
    answerRaw: answerRaw.present ? answerRaw.value : this.answerRaw,
    answerNormalized: answerNormalized.present
        ? answerNormalized.value
        : this.answerNormalized,
    answerEmpty: answerEmpty ?? this.answerEmpty,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
  );
  ExerciseAttemptRow copyWithCompanion(ExerciseAttemptsCompanion data) {
    return ExerciseAttemptRow(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      answerId: data.answerId.present ? data.answerId.value : this.answerId,
      answerRaw: data.answerRaw.present ? data.answerRaw.value : this.answerRaw,
      answerNormalized: data.answerNormalized.present
          ? data.answerNormalized.value
          : this.answerNormalized,
      answerEmpty: data.answerEmpty.present
          ? data.answerEmpty.value
          : this.answerEmpty,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttemptRow(')
          ..write('eventId: $eventId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('outcome: $outcome, ')
          ..write('answerId: $answerId, ')
          ..write('answerRaw: $answerRaw, ')
          ..write('answerNormalized: $answerNormalized, ')
          ..write('answerEmpty: $answerEmpty, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    exerciseId,
    startedAt,
    submittedAt,
    outcome,
    answerId,
    answerRaw,
    answerNormalized,
    answerEmpty,
    durationMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseAttemptRow &&
          other.eventId == this.eventId &&
          other.exerciseId == this.exerciseId &&
          other.startedAt == this.startedAt &&
          other.submittedAt == this.submittedAt &&
          other.outcome == this.outcome &&
          other.answerId == this.answerId &&
          other.answerRaw == this.answerRaw &&
          other.answerNormalized == this.answerNormalized &&
          other.answerEmpty == this.answerEmpty &&
          other.durationMs == this.durationMs);
}

class ExerciseAttemptsCompanion extends UpdateCompanion<ExerciseAttemptRow> {
  final Value<String> eventId;
  final Value<String> exerciseId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> submittedAt;
  final Value<AnswerOutcome> outcome;
  final Value<String?> answerId;
  final Value<String?> answerRaw;
  final Value<String?> answerNormalized;
  final Value<bool> answerEmpty;
  final Value<int?> durationMs;
  final Value<int> rowid;
  const ExerciseAttemptsCompanion({
    this.eventId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.answerId = const Value.absent(),
    this.answerRaw = const Value.absent(),
    this.answerNormalized = const Value.absent(),
    this.answerEmpty = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseAttemptsCompanion.insert({
    required String eventId,
    required String exerciseId,
    required DateTime startedAt,
    this.submittedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.answerId = const Value.absent(),
    this.answerRaw = const Value.absent(),
    this.answerNormalized = const Value.absent(),
    this.answerEmpty = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       exerciseId = Value(exerciseId),
       startedAt = Value(startedAt);
  static Insertable<ExerciseAttemptRow> custom({
    Expression<String>? eventId,
    Expression<String>? exerciseId,
    Expression<String>? startedAt,
    Expression<String>? submittedAt,
    Expression<String>? outcome,
    Expression<String>? answerId,
    Expression<String>? answerRaw,
    Expression<String>? answerNormalized,
    Expression<bool>? answerEmpty,
    Expression<int>? durationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (startedAt != null) 'started_at': startedAt,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (outcome != null) 'outcome': outcome,
      if (answerId != null) 'answer_id': answerId,
      if (answerRaw != null) 'answer_raw': answerRaw,
      if (answerNormalized != null) 'answer_normalized': answerNormalized,
      if (answerEmpty != null) 'answer_empty': answerEmpty,
      if (durationMs != null) 'duration_ms': durationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseAttemptsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? exerciseId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? submittedAt,
    Value<AnswerOutcome>? outcome,
    Value<String?>? answerId,
    Value<String?>? answerRaw,
    Value<String?>? answerNormalized,
    Value<bool>? answerEmpty,
    Value<int?>? durationMs,
    Value<int>? rowid,
  }) {
    return ExerciseAttemptsCompanion(
      eventId: eventId ?? this.eventId,
      exerciseId: exerciseId ?? this.exerciseId,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      outcome: outcome ?? this.outcome,
      answerId: answerId ?? this.answerId,
      answerRaw: answerRaw ?? this.answerRaw,
      answerNormalized: answerNormalized ?? this.answerNormalized,
      answerEmpty: answerEmpty ?? this.answerEmpty,
      durationMs: durationMs ?? this.durationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(
        $ExerciseAttemptsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<String>(
        $ExerciseAttemptsTable.$convertersubmittedAtn.toSql(submittedAt.value),
      );
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $ExerciseAttemptsTable.$converteroutcome.toSql(outcome.value),
      );
    }
    if (answerId.present) {
      map['answer_id'] = Variable<String>(answerId.value);
    }
    if (answerRaw.present) {
      map['answer_raw'] = Variable<String>(answerRaw.value);
    }
    if (answerNormalized.present) {
      map['answer_normalized'] = Variable<String>(answerNormalized.value);
    }
    if (answerEmpty.present) {
      map['answer_empty'] = Variable<bool>(answerEmpty.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttemptsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('outcome: $outcome, ')
          ..write('answerId: $answerId, ')
          ..write('answerRaw: $answerRaw, ')
          ..write('answerNormalized: $answerNormalized, ')
          ..write('answerEmpty: $answerEmpty, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObservedErrorsTable extends ObservedErrors
    with TableInfo<$ObservedErrorsTable, ObservedErrorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObservedErrorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learning_events (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> occurredAt =
      GeneratedColumn<String>(
        'occurred_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ObservedErrorsTable.$converteroccurredAt);
  static const VerificationMeta _errorTypeMeta = const VerificationMeta(
    'errorType',
  );
  @override
  late final GeneratedColumn<String> errorType = GeneratedColumn<String>(
    'error_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locatedAtMeta = const VerificationMeta(
    'locatedAt',
  );
  @override
  late final GeneratedColumn<String> locatedAt = GeneratedColumn<String>(
    'located_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    occurredAt,
    errorType,
    description,
    locatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'observed_errors';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObservedErrorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('error_type')) {
      context.handle(
        _errorTypeMeta,
        errorType.isAcceptableOrUnknown(data['error_type']!, _errorTypeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('located_at')) {
      context.handle(
        _locatedAtMeta,
        locatedAt.isAcceptableOrUnknown(data['located_at']!, _locatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ObservedErrorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObservedErrorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      occurredAt: $ObservedErrorsTable.$converteroccurredAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}occurred_at'],
        )!,
      ),
      errorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_type'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      locatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}located_at'],
      ),
    );
  }

  @override
  $ObservedErrorsTable createAlias(String alias) {
    return $ObservedErrorsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converteroccurredAt =
      const DateTimeUtcConverter();
}

class ObservedErrorRow extends DataClass
    implements Insertable<ObservedErrorRow> {
  final String id;
  final String eventId;
  final DateTime occurredAt;

  /// Marqueur technique ; NULL tant que l'erreur n'est pas identifiée.
  final String? errorType;
  final String? description;
  final String? locatedAt;
  const ObservedErrorRow({
    required this.id,
    required this.eventId,
    required this.occurredAt,
    this.errorType,
    this.description,
    this.locatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    {
      map['occurred_at'] = Variable<String>(
        $ObservedErrorsTable.$converteroccurredAt.toSql(occurredAt),
      );
    }
    if (!nullToAbsent || errorType != null) {
      map['error_type'] = Variable<String>(errorType);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || locatedAt != null) {
      map['located_at'] = Variable<String>(locatedAt);
    }
    return map;
  }

  ObservedErrorsCompanion toCompanion(bool nullToAbsent) {
    return ObservedErrorsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      occurredAt: Value(occurredAt),
      errorType: errorType == null && nullToAbsent
          ? const Value.absent()
          : Value(errorType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      locatedAt: locatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(locatedAt),
    );
  }

  factory ObservedErrorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObservedErrorRow(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      errorType: serializer.fromJson<String?>(json['errorType']),
      description: serializer.fromJson<String?>(json['description']),
      locatedAt: serializer.fromJson<String?>(json['locatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'errorType': serializer.toJson<String?>(errorType),
      'description': serializer.toJson<String?>(description),
      'locatedAt': serializer.toJson<String?>(locatedAt),
    };
  }

  ObservedErrorRow copyWith({
    String? id,
    String? eventId,
    DateTime? occurredAt,
    Value<String?> errorType = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> locatedAt = const Value.absent(),
  }) => ObservedErrorRow(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    occurredAt: occurredAt ?? this.occurredAt,
    errorType: errorType.present ? errorType.value : this.errorType,
    description: description.present ? description.value : this.description,
    locatedAt: locatedAt.present ? locatedAt.value : this.locatedAt,
  );
  ObservedErrorRow copyWithCompanion(ObservedErrorsCompanion data) {
    return ObservedErrorRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      errorType: data.errorType.present ? data.errorType.value : this.errorType,
      description: data.description.present
          ? data.description.value
          : this.description,
      locatedAt: data.locatedAt.present ? data.locatedAt.value : this.locatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObservedErrorRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('errorType: $errorType, ')
          ..write('description: $description, ')
          ..write('locatedAt: $locatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventId, occurredAt, errorType, description, locatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObservedErrorRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.occurredAt == this.occurredAt &&
          other.errorType == this.errorType &&
          other.description == this.description &&
          other.locatedAt == this.locatedAt);
}

class ObservedErrorsCompanion extends UpdateCompanion<ObservedErrorRow> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<DateTime> occurredAt;
  final Value<String?> errorType;
  final Value<String?> description;
  final Value<String?> locatedAt;
  final Value<int> rowid;
  const ObservedErrorsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.errorType = const Value.absent(),
    this.description = const Value.absent(),
    this.locatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObservedErrorsCompanion.insert({
    required String id,
    required String eventId,
    required DateTime occurredAt,
    this.errorType = const Value.absent(),
    this.description = const Value.absent(),
    this.locatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       occurredAt = Value(occurredAt);
  static Insertable<ObservedErrorRow> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? occurredAt,
    Expression<String>? errorType,
    Expression<String>? description,
    Expression<String>? locatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (errorType != null) 'error_type': errorType,
      if (description != null) 'description': description,
      if (locatedAt != null) 'located_at': locatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObservedErrorsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<DateTime>? occurredAt,
    Value<String?>? errorType,
    Value<String?>? description,
    Value<String?>? locatedAt,
    Value<int>? rowid,
  }) {
    return ObservedErrorsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      occurredAt: occurredAt ?? this.occurredAt,
      errorType: errorType ?? this.errorType,
      description: description ?? this.description,
      locatedAt: locatedAt ?? this.locatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(
        $ObservedErrorsTable.$converteroccurredAt.toSql(occurredAt.value),
      );
    }
    if (errorType.present) {
      map['error_type'] = Variable<String>(errorType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (locatedAt.present) {
      map['located_at'] = Variable<String>(locatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObservedErrorsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('errorType: $errorType, ')
          ..write('description: $description, ')
          ..write('locatedAt: $locatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfferedHintsTable extends OfferedHints
    with TableInfo<$OfferedHintsTable, OfferedHintRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfferedHintsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES learning_events (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> offeredAt =
      GeneratedColumn<String>(
        'offered_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($OfferedHintsTable.$converterofferedAt);
  static const VerificationMeta _hintIdMeta = const VerificationMeta('hintId');
  @override
  late final GeneratedColumn<String> hintId = GeneratedColumn<String>(
    'hint_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    offeredAt,
    hintId,
    kind,
    content,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offered_hints';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfferedHintRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('hint_id')) {
      context.handle(
        _hintIdMeta,
        hintId.isAcceptableOrUnknown(data['hint_id']!, _hintIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfferedHintRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfferedHintRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      offeredAt: $OfferedHintsTable.$converterofferedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}offered_at'],
        )!,
      ),
      hintId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hint_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
    );
  }

  @override
  $OfferedHintsTable createAlias(String alias) {
    return $OfferedHintsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterofferedAt =
      const DateTimeUtcConverter();
}

class OfferedHintRow extends DataClass implements Insertable<OfferedHintRow> {
  final String id;
  final String eventId;
  final DateTime offeredAt;
  final String? hintId;
  final String? kind;
  final String? content;
  const OfferedHintRow({
    required this.id,
    required this.eventId,
    required this.offeredAt,
    this.hintId,
    this.kind,
    this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    {
      map['offered_at'] = Variable<String>(
        $OfferedHintsTable.$converterofferedAt.toSql(offeredAt),
      );
    }
    if (!nullToAbsent || hintId != null) {
      map['hint_id'] = Variable<String>(hintId);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    return map;
  }

  OfferedHintsCompanion toCompanion(bool nullToAbsent) {
    return OfferedHintsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      offeredAt: Value(offeredAt),
      hintId: hintId == null && nullToAbsent
          ? const Value.absent()
          : Value(hintId),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
    );
  }

  factory OfferedHintRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfferedHintRow(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      offeredAt: serializer.fromJson<DateTime>(json['offeredAt']),
      hintId: serializer.fromJson<String?>(json['hintId']),
      kind: serializer.fromJson<String?>(json['kind']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'offeredAt': serializer.toJson<DateTime>(offeredAt),
      'hintId': serializer.toJson<String?>(hintId),
      'kind': serializer.toJson<String?>(kind),
      'content': serializer.toJson<String?>(content),
    };
  }

  OfferedHintRow copyWith({
    String? id,
    String? eventId,
    DateTime? offeredAt,
    Value<String?> hintId = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    Value<String?> content = const Value.absent(),
  }) => OfferedHintRow(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    offeredAt: offeredAt ?? this.offeredAt,
    hintId: hintId.present ? hintId.value : this.hintId,
    kind: kind.present ? kind.value : this.kind,
    content: content.present ? content.value : this.content,
  );
  OfferedHintRow copyWithCompanion(OfferedHintsCompanion data) {
    return OfferedHintRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      offeredAt: data.offeredAt.present ? data.offeredAt.value : this.offeredAt,
      hintId: data.hintId.present ? data.hintId.value : this.hintId,
      kind: data.kind.present ? data.kind.value : this.kind,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfferedHintRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('offeredAt: $offeredAt, ')
          ..write('hintId: $hintId, ')
          ..write('kind: $kind, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventId, offeredAt, hintId, kind, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfferedHintRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.offeredAt == this.offeredAt &&
          other.hintId == this.hintId &&
          other.kind == this.kind &&
          other.content == this.content);
}

class OfferedHintsCompanion extends UpdateCompanion<OfferedHintRow> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<DateTime> offeredAt;
  final Value<String?> hintId;
  final Value<String?> kind;
  final Value<String?> content;
  final Value<int> rowid;
  const OfferedHintsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.offeredAt = const Value.absent(),
    this.hintId = const Value.absent(),
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfferedHintsCompanion.insert({
    required String id,
    required String eventId,
    required DateTime offeredAt,
    this.hintId = const Value.absent(),
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       offeredAt = Value(offeredAt);
  static Insertable<OfferedHintRow> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? offeredAt,
    Expression<String>? hintId,
    Expression<String>? kind,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (offeredAt != null) 'offered_at': offeredAt,
      if (hintId != null) 'hint_id': hintId,
      if (kind != null) 'kind': kind,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfferedHintsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<DateTime>? offeredAt,
    Value<String?>? hintId,
    Value<String?>? kind,
    Value<String?>? content,
    Value<int>? rowid,
  }) {
    return OfferedHintsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      offeredAt: offeredAt ?? this.offeredAt,
      hintId: hintId ?? this.hintId,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (offeredAt.present) {
      map['offered_at'] = Variable<String>(
        $OfferedHintsTable.$converterofferedAt.toSql(offeredAt.value),
      );
    }
    if (hintId.present) {
      map['hint_id'] = Variable<String>(hintId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfferedHintsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('offeredAt: $offeredAt, ')
          ..write('hintId: $hintId, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotionsTable notions = $NotionsTable(this);
  late final $MathDomainsTable mathDomains = $MathDomainsTable(this);
  late final $NotionLevelsTable notionLevels = $NotionLevelsTable(this);
  late final $NotionPrerequisitesTable notionPrerequisites =
      $NotionPrerequisitesTable(this);
  late final $LearningEventsTable learningEvents = $LearningEventsTable(this);
  late final $EventNotionsTable eventNotions = $EventNotionsTable(this);
  late final $ExerciseAttemptsTable exerciseAttempts = $ExerciseAttemptsTable(
    this,
  );
  late final $ObservedErrorsTable observedErrors = $ObservedErrorsTable(this);
  late final $OfferedHintsTable offeredHints = $OfferedHintsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notions,
    mathDomains,
    notionLevels,
    notionPrerequisites,
    learningEvents,
    eventNotions,
    exerciseAttempts,
    observedErrors,
    offeredHints,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learning_events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_notions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learning_events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_attempts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learning_events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('observed_errors', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'learning_events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('offered_hints', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$NotionsTableCreateCompanionBuilder = NotionsCompanion Function({
  required String id,
  required String label,
  Value<String?> description,
  Value<String?> domainId,
  Value<String?> levelId,
  Value<NotionLifecycle> lifecycle,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$NotionsTableUpdateCompanionBuilder = NotionsCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String?> description,
  Value<String?> domainId,
  Value<String?> levelId,
  Value<NotionLifecycle> lifecycle,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$NotionsTableFilterComposer
    extends Composer<_$AppDatabase, $NotionsTable> {
  $$NotionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domainId => $composableBuilder(
    column: $table.domainId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NotionLifecycle, NotionLifecycle, String>
  get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$NotionsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotionsTable> {
  $$NotionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domainId => $composableBuilder(
    column: $table.domainId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotionsTable> {
  $$NotionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domainId =>
      $composableBuilder(column: $table.domainId, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NotionLifecycle, String> get lifecycle =>
      $composableBuilder(column: $table.lifecycle, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotionsTable,
          NotionRow,
          $$NotionsTableFilterComposer,
          $$NotionsTableOrderingComposer,
          $$NotionsTableAnnotationComposer,
          $$NotionsTableCreateCompanionBuilder,
          $$NotionsTableUpdateCompanionBuilder,
          (NotionRow, BaseReferences<_$AppDatabase, $NotionsTable, NotionRow>),
          NotionRow,
          PrefetchHooks Function()
        > {
  $$NotionsTableTableManager(_$AppDatabase db, $NotionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> domainId = const Value.absent(),
                Value<String?> levelId = const Value.absent(),
                Value<NotionLifecycle> lifecycle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotionsCompanion(
                id: id,
                label: label,
                description: description,
                domainId: domainId,
                levelId: levelId,
                lifecycle: lifecycle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                Value<String?> description = const Value.absent(),
                Value<String?> domainId = const Value.absent(),
                Value<String?> levelId = const Value.absent(),
                Value<NotionLifecycle> lifecycle = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotionsCompanion.insert(
                id: id,
                label: label,
                description: description,
                domainId: domainId,
                levelId: levelId,
                lifecycle: lifecycle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotionsTable, NotionRow>(table),
                  BaseReferences<_$AppDatabase, $NotionsTable, NotionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotionsTable,
      NotionRow,
      $$NotionsTableFilterComposer,
      $$NotionsTableOrderingComposer,
      $$NotionsTableAnnotationComposer,
      $$NotionsTableCreateCompanionBuilder,
      $$NotionsTableUpdateCompanionBuilder,
      (NotionRow, BaseReferences<_$AppDatabase, $NotionsTable, NotionRow>),
      NotionRow,
      PrefetchHooks Function()
    >;
typedef $$MathDomainsTableCreateCompanionBuilder =
    MathDomainsCompanion Function({
      required String id,
      required String label,
      Value<int> rowid,
    });
typedef $$MathDomainsTableUpdateCompanionBuilder =
    MathDomainsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<int> rowid,
    });

class $$MathDomainsTableFilterComposer
    extends Composer<_$AppDatabase, $MathDomainsTable> {
  $$MathDomainsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MathDomainsTableOrderingComposer
    extends Composer<_$AppDatabase, $MathDomainsTable> {
  $$MathDomainsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MathDomainsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MathDomainsTable> {
  $$MathDomainsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$MathDomainsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MathDomainsTable,
          MathDomainRow,
          $$MathDomainsTableFilterComposer,
          $$MathDomainsTableOrderingComposer,
          $$MathDomainsTableAnnotationComposer,
          $$MathDomainsTableCreateCompanionBuilder,
          $$MathDomainsTableUpdateCompanionBuilder,
          (
            MathDomainRow,
            BaseReferences<_$AppDatabase, $MathDomainsTable, MathDomainRow>,
          ),
          MathDomainRow,
          PrefetchHooks Function()
        > {
  $$MathDomainsTableTableManager(_$AppDatabase db, $MathDomainsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MathDomainsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MathDomainsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MathDomainsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MathDomainsCompanion(id: id, label: label, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String label,
            Value<int> rowid = const Value.absent(),
          }) => MathDomainsCompanion.insert(id: id, label: label, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MathDomainsTable, MathDomainRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MathDomainsTable,
                    MathDomainRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MathDomainsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MathDomainsTable,
      MathDomainRow,
      $$MathDomainsTableFilterComposer,
      $$MathDomainsTableOrderingComposer,
      $$MathDomainsTableAnnotationComposer,
      $$MathDomainsTableCreateCompanionBuilder,
      $$MathDomainsTableUpdateCompanionBuilder,
      (
        MathDomainRow,
        BaseReferences<_$AppDatabase, $MathDomainsTable, MathDomainRow>,
      ),
      MathDomainRow,
      PrefetchHooks Function()
    >;
typedef $$NotionLevelsTableCreateCompanionBuilder =
    NotionLevelsCompanion Function({
      required String id,
      required String label,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$NotionLevelsTableUpdateCompanionBuilder =
    NotionLevelsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$NotionLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $NotionLevelsTable> {
  $$NotionLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotionLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotionLevelsTable> {
  $$NotionLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotionLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotionLevelsTable> {
  $$NotionLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$NotionLevelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotionLevelsTable,
          NotionLevelRow,
          $$NotionLevelsTableFilterComposer,
          $$NotionLevelsTableOrderingComposer,
          $$NotionLevelsTableAnnotationComposer,
          $$NotionLevelsTableCreateCompanionBuilder,
          $$NotionLevelsTableUpdateCompanionBuilder,
          (
            NotionLevelRow,
            BaseReferences<_$AppDatabase, $NotionLevelsTable, NotionLevelRow>,
          ),
          NotionLevelRow,
          PrefetchHooks Function()
        > {
  $$NotionLevelsTableTableManager(_$AppDatabase db, $NotionLevelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotionLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotionLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotionLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotionLevelsCompanion(
                id: id,
                label: label,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => NotionLevelsCompanion.insert(
                id: id,
                label: label,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotionLevelsTable, NotionLevelRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NotionLevelsTable,
                    NotionLevelRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotionLevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotionLevelsTable,
      NotionLevelRow,
      $$NotionLevelsTableFilterComposer,
      $$NotionLevelsTableOrderingComposer,
      $$NotionLevelsTableAnnotationComposer,
      $$NotionLevelsTableCreateCompanionBuilder,
      $$NotionLevelsTableUpdateCompanionBuilder,
      (
        NotionLevelRow,
        BaseReferences<_$AppDatabase, $NotionLevelsTable, NotionLevelRow>,
      ),
      NotionLevelRow,
      PrefetchHooks Function()
    >;
typedef $$NotionPrerequisitesTableCreateCompanionBuilder =
    NotionPrerequisitesCompanion Function({
      required String prerequisiteId,
      required String notionId,
      Value<int> rowid,
    });
typedef $$NotionPrerequisitesTableUpdateCompanionBuilder =
    NotionPrerequisitesCompanion Function({
      Value<String> prerequisiteId,
      Value<String> notionId,
      Value<int> rowid,
    });

class $$NotionPrerequisitesTableFilterComposer
    extends Composer<_$AppDatabase, $NotionPrerequisitesTable> {
  $$NotionPrerequisitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get prerequisiteId => $composableBuilder(
    column: $table.prerequisiteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notionId => $composableBuilder(
    column: $table.notionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotionPrerequisitesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotionPrerequisitesTable> {
  $$NotionPrerequisitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get prerequisiteId => $composableBuilder(
    column: $table.prerequisiteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notionId => $composableBuilder(
    column: $table.notionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotionPrerequisitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotionPrerequisitesTable> {
  $$NotionPrerequisitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get prerequisiteId => $composableBuilder(
    column: $table.prerequisiteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notionId =>
      $composableBuilder(column: $table.notionId, builder: (column) => column);
}

class $$NotionPrerequisitesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotionPrerequisitesTable,
          NotionPrerequisiteRow,
          $$NotionPrerequisitesTableFilterComposer,
          $$NotionPrerequisitesTableOrderingComposer,
          $$NotionPrerequisitesTableAnnotationComposer,
          $$NotionPrerequisitesTableCreateCompanionBuilder,
          $$NotionPrerequisitesTableUpdateCompanionBuilder,
          (
            NotionPrerequisiteRow,
            BaseReferences<
              _$AppDatabase,
              $NotionPrerequisitesTable,
              NotionPrerequisiteRow
            >,
          ),
          NotionPrerequisiteRow,
          PrefetchHooks Function()
        > {
  $$NotionPrerequisitesTableTableManager(
    _$AppDatabase db,
    $NotionPrerequisitesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotionPrerequisitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotionPrerequisitesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotionPrerequisitesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> prerequisiteId = const Value.absent(),
                Value<String> notionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotionPrerequisitesCompanion(
                prerequisiteId: prerequisiteId,
                notionId: notionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String prerequisiteId,
                required String notionId,
                Value<int> rowid = const Value.absent(),
              }) => NotionPrerequisitesCompanion.insert(
                prerequisiteId: prerequisiteId,
                notionId: notionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotionPrerequisitesTable, NotionPrerequisiteRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $NotionPrerequisitesTable,
                    NotionPrerequisiteRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotionPrerequisitesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotionPrerequisitesTable,
      NotionPrerequisiteRow,
      $$NotionPrerequisitesTableFilterComposer,
      $$NotionPrerequisitesTableOrderingComposer,
      $$NotionPrerequisitesTableAnnotationComposer,
      $$NotionPrerequisitesTableCreateCompanionBuilder,
      $$NotionPrerequisitesTableUpdateCompanionBuilder,
      (
        NotionPrerequisiteRow,
        BaseReferences<
          _$AppDatabase,
          $NotionPrerequisitesTable,
          NotionPrerequisiteRow
        >,
      ),
      NotionPrerequisiteRow,
      PrefetchHooks Function()
    >;
typedef $$LearningEventsTableCreateCompanionBuilder =
    LearningEventsCompanion Function({
      required String id,
      required String type,
      required DateTime occurredAt,
      Value<String?> contextJson,
      Value<String> metadataJson,
      required DateTime recordedAt,
      Value<int> rowid,
    });
typedef $$LearningEventsTableUpdateCompanionBuilder =
    LearningEventsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<DateTime> occurredAt,
      Value<String?> contextJson,
      Value<String> metadataJson,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$LearningEventsTableReferences
    extends
        BaseReferences<_$AppDatabase, $LearningEventsTable, LearningEventRow> {
  $$LearningEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$EventNotionsTable, List<EventNotionRow>>
  _eventNotionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventNotions,
    aliasName: 'learning_events__id__event_notions__event_id',
  );

  $$EventNotionsTableProcessedTableManager get eventNotionsRefs {
    final manager = $$EventNotionsTableTableManager(
      $_db,
      $_db.eventNotions,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventNotionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExerciseAttemptsTable, List<ExerciseAttemptRow>>
  _exerciseAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseAttempts,
    aliasName: 'learning_events__id__exercise_attempts__event_id',
  );

  $$ExerciseAttemptsTableProcessedTableManager get exerciseAttemptsRefs {
    final manager = $$ExerciseAttemptsTableTableManager(
      $_db,
      $_db.exerciseAttempts,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ObservedErrorsTable, List<ObservedErrorRow>>
  _observedErrorsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.observedErrors,
    aliasName: 'learning_events__id__observed_errors__event_id',
  );

  $$ObservedErrorsTableProcessedTableManager get observedErrorsRefs {
    final manager = $$ObservedErrorsTableTableManager(
      $_db,
      $_db.observedErrors,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_observedErrorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OfferedHintsTable, List<OfferedHintRow>>
  _offeredHintsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.offeredHints,
    aliasName: 'learning_events__id__offered_hints__event_id',
  );

  $$OfferedHintsTableProcessedTableManager get offeredHintsRefs {
    final manager = $$OfferedHintsTableTableManager(
      $_db,
      $_db.offeredHints,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_offeredHintsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LearningEventsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningEventsTable> {
  $$LearningEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get recordedAt =>
      $composableBuilder(
        column: $table.recordedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> eventNotionsRefs(
    Expression<bool> Function($$EventNotionsTableFilterComposer f) f,
  ) {
    final $$EventNotionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventNotions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventNotionsTableFilterComposer(
            $db: $db,
            $table: $db.eventNotions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseAttemptsRefs(
    Expression<bool> Function($$ExerciseAttemptsTableFilterComposer f) f,
  ) {
    final $$ExerciseAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseAttempts,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> observedErrorsRefs(
    Expression<bool> Function($$ObservedErrorsTableFilterComposer f) f,
  ) {
    final $$ObservedErrorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observedErrors,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservedErrorsTableFilterComposer(
            $db: $db,
            $table: $db.observedErrors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> offeredHintsRefs(
    Expression<bool> Function($$OfferedHintsTableFilterComposer f) f,
  ) {
    final $$OfferedHintsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.offeredHints,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OfferedHintsTableFilterComposer(
            $db: $db,
            $table: $db.offeredHints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearningEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningEventsTable> {
  $$LearningEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningEventsTable> {
  $$LearningEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get recordedAt =>
      $composableBuilder(
        column: $table.recordedAt,
        builder: (column) => column,
      );

  Expression<T> eventNotionsRefs<T extends Object>(
    Expression<T> Function($$EventNotionsTableAnnotationComposer a) f,
  ) {
    final $$EventNotionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventNotions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventNotionsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventNotions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exerciseAttemptsRefs<T extends Object>(
    Expression<T> Function($$ExerciseAttemptsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseAttempts,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> observedErrorsRefs<T extends Object>(
    Expression<T> Function($$ObservedErrorsTableAnnotationComposer a) f,
  ) {
    final $$ObservedErrorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observedErrors,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservedErrorsTableAnnotationComposer(
            $db: $db,
            $table: $db.observedErrors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> offeredHintsRefs<T extends Object>(
    Expression<T> Function($$OfferedHintsTableAnnotationComposer a) f,
  ) {
    final $$OfferedHintsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.offeredHints,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OfferedHintsTableAnnotationComposer(
            $db: $db,
            $table: $db.offeredHints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LearningEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningEventsTable,
          LearningEventRow,
          $$LearningEventsTableFilterComposer,
          $$LearningEventsTableOrderingComposer,
          $$LearningEventsTableAnnotationComposer,
          $$LearningEventsTableCreateCompanionBuilder,
          $$LearningEventsTableUpdateCompanionBuilder,
          (LearningEventRow, $$LearningEventsTableReferences),
          LearningEventRow,
          PrefetchHooks Function({
            bool eventNotionsRefs,
            bool exerciseAttemptsRefs,
            bool observedErrorsRefs,
            bool offeredHintsRefs,
          })
        > {
  $$LearningEventsTableTableManager(
    _$AppDatabase db,
    $LearningEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> contextJson = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningEventsCompanion(
                id: id,
                type: type,
                occurredAt: occurredAt,
                contextJson: contextJson,
                metadataJson: metadataJson,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required DateTime occurredAt,
                Value<String?> contextJson = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => LearningEventsCompanion.insert(
                id: id,
                type: type,
                occurredAt: occurredAt,
                contextJson: contextJson,
                metadataJson: metadataJson,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LearningEventsTable, LearningEventRow>(table),
                  $$LearningEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                eventNotionsRefs = false,
                exerciseAttemptsRefs = false,
                observedErrorsRefs = false,
                offeredHintsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventNotionsRefs) db.eventNotions,
                    if (exerciseAttemptsRefs) db.exerciseAttempts,
                    if (observedErrorsRefs) db.observedErrors,
                    if (offeredHintsRefs) db.offeredHints,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventNotionsRefs)
                        await $_getPrefetchedData<
                          LearningEventRow,
                          $LearningEventsTable,
                          EventNotionRow
                        >(
                          currentTable: table,
                          referencedTable: $$LearningEventsTableReferences
                              ._eventNotionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearningEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventNotionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseAttemptsRefs)
                        await $_getPrefetchedData<
                          LearningEventRow,
                          $LearningEventsTable,
                          ExerciseAttemptRow
                        >(
                          currentTable: table,
                          referencedTable: $$LearningEventsTableReferences
                              ._exerciseAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearningEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (observedErrorsRefs)
                        await $_getPrefetchedData<
                          LearningEventRow,
                          $LearningEventsTable,
                          ObservedErrorRow
                        >(
                          currentTable: table,
                          referencedTable: $$LearningEventsTableReferences
                              ._observedErrorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearningEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).observedErrorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (offeredHintsRefs)
                        await $_getPrefetchedData<
                          LearningEventRow,
                          $LearningEventsTable,
                          OfferedHintRow
                        >(
                          currentTable: table,
                          referencedTable: $$LearningEventsTableReferences
                              ._offeredHintsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LearningEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).offeredHintsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LearningEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningEventsTable,
      LearningEventRow,
      $$LearningEventsTableFilterComposer,
      $$LearningEventsTableOrderingComposer,
      $$LearningEventsTableAnnotationComposer,
      $$LearningEventsTableCreateCompanionBuilder,
      $$LearningEventsTableUpdateCompanionBuilder,
      (LearningEventRow, $$LearningEventsTableReferences),
      LearningEventRow,
      PrefetchHooks Function({
        bool eventNotionsRefs,
        bool exerciseAttemptsRefs,
        bool observedErrorsRefs,
        bool offeredHintsRefs,
      })
    >;
typedef $$EventNotionsTableCreateCompanionBuilder =
    EventNotionsCompanion Function({
      required String eventId,
      required String notionId,
      Value<int> rowid,
    });
typedef $$EventNotionsTableUpdateCompanionBuilder =
    EventNotionsCompanion Function({
      Value<String> eventId,
      Value<String> notionId,
      Value<int> rowid,
    });

final class $$EventNotionsTableReferences
    extends BaseReferences<_$AppDatabase, $EventNotionsTable, EventNotionRow> {
  $$EventNotionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LearningEventsTable _eventIdTable(_$AppDatabase db) => db
      .learningEvents
      .createAlias('event_notions__event_id__learning_events__id');

  $$LearningEventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$LearningEventsTableTableManager(
      $_db,
      $_db.learningEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventNotionsTableFilterComposer
    extends Composer<_$AppDatabase, $EventNotionsTable> {
  $$EventNotionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get notionId => $composableBuilder(
    column: $table.notionId,
    builder: (column) => ColumnFilters(column),
  );

  $$LearningEventsTableFilterComposer get eventId {
    final $$LearningEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableFilterComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventNotionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventNotionsTable> {
  $$EventNotionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get notionId => $composableBuilder(
    column: $table.notionId,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearningEventsTableOrderingComposer get eventId {
    final $$LearningEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableOrderingComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventNotionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventNotionsTable> {
  $$EventNotionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get notionId =>
      $composableBuilder(column: $table.notionId, builder: (column) => column);

  $$LearningEventsTableAnnotationComposer get eventId {
    final $$LearningEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventNotionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventNotionsTable,
          EventNotionRow,
          $$EventNotionsTableFilterComposer,
          $$EventNotionsTableOrderingComposer,
          $$EventNotionsTableAnnotationComposer,
          $$EventNotionsTableCreateCompanionBuilder,
          $$EventNotionsTableUpdateCompanionBuilder,
          (EventNotionRow, $$EventNotionsTableReferences),
          EventNotionRow,
          PrefetchHooks Function({bool eventId})
        > {
  $$EventNotionsTableTableManager(_$AppDatabase db, $EventNotionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventNotionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventNotionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventNotionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> notionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventNotionsCompanion(
                eventId: eventId,
                notionId: notionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String notionId,
                Value<int> rowid = const Value.absent(),
              }) => EventNotionsCompanion.insert(
                eventId: eventId,
                notionId: notionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventNotionsTable, EventNotionRow>(table),
                  $$EventNotionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$EventNotionsTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$EventNotionsTableReferences
                            ._eventIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EventNotionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventNotionsTable,
      EventNotionRow,
      $$EventNotionsTableFilterComposer,
      $$EventNotionsTableOrderingComposer,
      $$EventNotionsTableAnnotationComposer,
      $$EventNotionsTableCreateCompanionBuilder,
      $$EventNotionsTableUpdateCompanionBuilder,
      (EventNotionRow, $$EventNotionsTableReferences),
      EventNotionRow,
      PrefetchHooks Function({bool eventId})
    >;
typedef $$ExerciseAttemptsTableCreateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      required String eventId,
      required String exerciseId,
      required DateTime startedAt,
      Value<DateTime?> submittedAt,
      Value<AnswerOutcome> outcome,
      Value<String?> answerId,
      Value<String?> answerRaw,
      Value<String?> answerNormalized,
      Value<bool> answerEmpty,
      Value<int?> durationMs,
      Value<int> rowid,
    });
typedef $$ExerciseAttemptsTableUpdateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      Value<String> eventId,
      Value<String> exerciseId,
      Value<DateTime> startedAt,
      Value<DateTime?> submittedAt,
      Value<AnswerOutcome> outcome,
      Value<String?> answerId,
      Value<String?> answerRaw,
      Value<String?> answerNormalized,
      Value<bool> answerEmpty,
      Value<int?> durationMs,
      Value<int> rowid,
    });

final class $$ExerciseAttemptsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseAttemptsTable,
          ExerciseAttemptRow
        > {
  $$ExerciseAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearningEventsTable _eventIdTable(_$AppDatabase db) => db
      .learningEvents
      .createAlias('exercise_attempts__event_id__learning_events__id');

  $$LearningEventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$LearningEventsTableTableManager(
      $_db,
      $_db.learningEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get submittedAt =>
      $composableBuilder(
        column: $table.submittedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AnswerOutcome, AnswerOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerRaw => $composableBuilder(
    column: $table.answerRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerNormalized => $composableBuilder(
    column: $table.answerNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get answerEmpty => $composableBuilder(
    column: $table.answerEmpty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  $$LearningEventsTableFilterComposer get eventId {
    final $$LearningEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableFilterComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerRaw => $composableBuilder(
    column: $table.answerRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerNormalized => $composableBuilder(
    column: $table.answerNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get answerEmpty => $composableBuilder(
    column: $table.answerEmpty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearningEventsTableOrderingComposer get eventId {
    final $$LearningEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableOrderingComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get submittedAt =>
      $composableBuilder(
        column: $table.submittedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<AnswerOutcome, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get answerId =>
      $composableBuilder(column: $table.answerId, builder: (column) => column);

  GeneratedColumn<String> get answerRaw =>
      $composableBuilder(column: $table.answerRaw, builder: (column) => column);

  GeneratedColumn<String> get answerNormalized => $composableBuilder(
    column: $table.answerNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get answerEmpty => $composableBuilder(
    column: $table.answerEmpty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  $$LearningEventsTableAnnotationComposer get eventId {
    final $$LearningEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseAttemptsTable,
          ExerciseAttemptRow,
          $$ExerciseAttemptsTableFilterComposer,
          $$ExerciseAttemptsTableOrderingComposer,
          $$ExerciseAttemptsTableAnnotationComposer,
          $$ExerciseAttemptsTableCreateCompanionBuilder,
          $$ExerciseAttemptsTableUpdateCompanionBuilder,
          (ExerciseAttemptRow, $$ExerciseAttemptsTableReferences),
          ExerciseAttemptRow,
          PrefetchHooks Function({bool eventId})
        > {
  $$ExerciseAttemptsTableTableManager(
    _$AppDatabase db,
    $ExerciseAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<AnswerOutcome> outcome = const Value.absent(),
                Value<String?> answerId = const Value.absent(),
                Value<String?> answerRaw = const Value.absent(),
                Value<String?> answerNormalized = const Value.absent(),
                Value<bool> answerEmpty = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseAttemptsCompanion(
                eventId: eventId,
                exerciseId: exerciseId,
                startedAt: startedAt,
                submittedAt: submittedAt,
                outcome: outcome,
                answerId: answerId,
                answerRaw: answerRaw,
                answerNormalized: answerNormalized,
                answerEmpty: answerEmpty,
                durationMs: durationMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String exerciseId,
                required DateTime startedAt,
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<AnswerOutcome> outcome = const Value.absent(),
                Value<String?> answerId = const Value.absent(),
                Value<String?> answerRaw = const Value.absent(),
                Value<String?> answerNormalized = const Value.absent(),
                Value<bool> answerEmpty = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseAttemptsCompanion.insert(
                eventId: eventId,
                exerciseId: exerciseId,
                startedAt: startedAt,
                submittedAt: submittedAt,
                outcome: outcome,
                answerId: answerId,
                answerRaw: answerRaw,
                answerNormalized: answerNormalized,
                answerEmpty: answerEmpty,
                durationMs: durationMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseAttemptsTable, ExerciseAttemptRow>(
                    table,
                  ),
                  $$ExerciseAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$ExerciseAttemptsTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$ExerciseAttemptsTableReferences
                            ._eventIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseAttemptsTable,
      ExerciseAttemptRow,
      $$ExerciseAttemptsTableFilterComposer,
      $$ExerciseAttemptsTableOrderingComposer,
      $$ExerciseAttemptsTableAnnotationComposer,
      $$ExerciseAttemptsTableCreateCompanionBuilder,
      $$ExerciseAttemptsTableUpdateCompanionBuilder,
      (ExerciseAttemptRow, $$ExerciseAttemptsTableReferences),
      ExerciseAttemptRow,
      PrefetchHooks Function({bool eventId})
    >;
typedef $$ObservedErrorsTableCreateCompanionBuilder =
    ObservedErrorsCompanion Function({
      required String id,
      required String eventId,
      required DateTime occurredAt,
      Value<String?> errorType,
      Value<String?> description,
      Value<String?> locatedAt,
      Value<int> rowid,
    });
typedef $$ObservedErrorsTableUpdateCompanionBuilder =
    ObservedErrorsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<DateTime> occurredAt,
      Value<String?> errorType,
      Value<String?> description,
      Value<String?> locatedAt,
      Value<int> rowid,
    });

final class $$ObservedErrorsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ObservedErrorsTable, ObservedErrorRow> {
  $$ObservedErrorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LearningEventsTable _eventIdTable(_$AppDatabase db) => db
      .learningEvents
      .createAlias('observed_errors__event_id__learning_events__id');

  $$LearningEventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$LearningEventsTableTableManager(
      $_db,
      $_db.learningEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ObservedErrorsTableFilterComposer
    extends Composer<_$AppDatabase, $ObservedErrorsTable> {
  $$ObservedErrorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get errorType => $composableBuilder(
    column: $table.errorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locatedAt => $composableBuilder(
    column: $table.locatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LearningEventsTableFilterComposer get eventId {
    final $$LearningEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableFilterComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObservedErrorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ObservedErrorsTable> {
  $$ObservedErrorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorType => $composableBuilder(
    column: $table.errorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locatedAt => $composableBuilder(
    column: $table.locatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearningEventsTableOrderingComposer get eventId {
    final $$LearningEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableOrderingComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObservedErrorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObservedErrorsTable> {
  $$ObservedErrorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get occurredAt =>
      $composableBuilder(
        column: $table.occurredAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get errorType =>
      $composableBuilder(column: $table.errorType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locatedAt =>
      $composableBuilder(column: $table.locatedAt, builder: (column) => column);

  $$LearningEventsTableAnnotationComposer get eventId {
    final $$LearningEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObservedErrorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ObservedErrorsTable,
          ObservedErrorRow,
          $$ObservedErrorsTableFilterComposer,
          $$ObservedErrorsTableOrderingComposer,
          $$ObservedErrorsTableAnnotationComposer,
          $$ObservedErrorsTableCreateCompanionBuilder,
          $$ObservedErrorsTableUpdateCompanionBuilder,
          (ObservedErrorRow, $$ObservedErrorsTableReferences),
          ObservedErrorRow,
          PrefetchHooks Function({bool eventId})
        > {
  $$ObservedErrorsTableTableManager(
    _$AppDatabase db,
    $ObservedErrorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObservedErrorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObservedErrorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObservedErrorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> errorType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> locatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObservedErrorsCompanion(
                id: id,
                eventId: eventId,
                occurredAt: occurredAt,
                errorType: errorType,
                description: description,
                locatedAt: locatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required DateTime occurredAt,
                Value<String?> errorType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> locatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObservedErrorsCompanion.insert(
                id: id,
                eventId: eventId,
                occurredAt: occurredAt,
                errorType: errorType,
                description: description,
                locatedAt: locatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ObservedErrorsTable, ObservedErrorRow>(table),
                  $$ObservedErrorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$ObservedErrorsTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$ObservedErrorsTableReferences
                            ._eventIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ObservedErrorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ObservedErrorsTable,
      ObservedErrorRow,
      $$ObservedErrorsTableFilterComposer,
      $$ObservedErrorsTableOrderingComposer,
      $$ObservedErrorsTableAnnotationComposer,
      $$ObservedErrorsTableCreateCompanionBuilder,
      $$ObservedErrorsTableUpdateCompanionBuilder,
      (ObservedErrorRow, $$ObservedErrorsTableReferences),
      ObservedErrorRow,
      PrefetchHooks Function({bool eventId})
    >;
typedef $$OfferedHintsTableCreateCompanionBuilder =
    OfferedHintsCompanion Function({
      required String id,
      required String eventId,
      required DateTime offeredAt,
      Value<String?> hintId,
      Value<String?> kind,
      Value<String?> content,
      Value<int> rowid,
    });
typedef $$OfferedHintsTableUpdateCompanionBuilder =
    OfferedHintsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<DateTime> offeredAt,
      Value<String?> hintId,
      Value<String?> kind,
      Value<String?> content,
      Value<int> rowid,
    });

final class $$OfferedHintsTableReferences
    extends BaseReferences<_$AppDatabase, $OfferedHintsTable, OfferedHintRow> {
  $$OfferedHintsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LearningEventsTable _eventIdTable(_$AppDatabase db) => db
      .learningEvents
      .createAlias('offered_hints__event_id__learning_events__id');

  $$LearningEventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$LearningEventsTableTableManager(
      $_db,
      $_db.learningEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OfferedHintsTableFilterComposer
    extends Composer<_$AppDatabase, $OfferedHintsTable> {
  $$OfferedHintsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get offeredAt =>
      $composableBuilder(
        column: $table.offeredAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get hintId => $composableBuilder(
    column: $table.hintId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  $$LearningEventsTableFilterComposer get eventId {
    final $$LearningEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableFilterComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OfferedHintsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfferedHintsTable> {
  $$OfferedHintsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offeredAt => $composableBuilder(
    column: $table.offeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hintId => $composableBuilder(
    column: $table.hintId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  $$LearningEventsTableOrderingComposer get eventId {
    final $$LearningEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableOrderingComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OfferedHintsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfferedHintsTable> {
  $$OfferedHintsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get offeredAt =>
      $composableBuilder(column: $table.offeredAt, builder: (column) => column);

  GeneratedColumn<String> get hintId =>
      $composableBuilder(column: $table.hintId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  $$LearningEventsTableAnnotationComposer get eventId {
    final $$LearningEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.learningEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OfferedHintsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfferedHintsTable,
          OfferedHintRow,
          $$OfferedHintsTableFilterComposer,
          $$OfferedHintsTableOrderingComposer,
          $$OfferedHintsTableAnnotationComposer,
          $$OfferedHintsTableCreateCompanionBuilder,
          $$OfferedHintsTableUpdateCompanionBuilder,
          (OfferedHintRow, $$OfferedHintsTableReferences),
          OfferedHintRow,
          PrefetchHooks Function({bool eventId})
        > {
  $$OfferedHintsTableTableManager(_$AppDatabase db, $OfferedHintsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfferedHintsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfferedHintsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfferedHintsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<DateTime> offeredAt = const Value.absent(),
                Value<String?> hintId = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfferedHintsCompanion(
                id: id,
                eventId: eventId,
                offeredAt: offeredAt,
                hintId: hintId,
                kind: kind,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required DateTime offeredAt,
                Value<String?> hintId = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfferedHintsCompanion.insert(
                id: id,
                eventId: eventId,
                offeredAt: offeredAt,
                hintId: hintId,
                kind: kind,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfferedHintsTable, OfferedHintRow>(table),
                  $$OfferedHintsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$OfferedHintsTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$OfferedHintsTableReferences
                            ._eventIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OfferedHintsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfferedHintsTable,
      OfferedHintRow,
      $$OfferedHintsTableFilterComposer,
      $$OfferedHintsTableOrderingComposer,
      $$OfferedHintsTableAnnotationComposer,
      $$OfferedHintsTableCreateCompanionBuilder,
      $$OfferedHintsTableUpdateCompanionBuilder,
      (OfferedHintRow, $$OfferedHintsTableReferences),
      OfferedHintRow,
      PrefetchHooks Function({bool eventId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotionsTableTableManager get notions =>
      $$NotionsTableTableManager(_db, _db.notions);
  $$MathDomainsTableTableManager get mathDomains =>
      $$MathDomainsTableTableManager(_db, _db.mathDomains);
  $$NotionLevelsTableTableManager get notionLevels =>
      $$NotionLevelsTableTableManager(_db, _db.notionLevels);
  $$NotionPrerequisitesTableTableManager get notionPrerequisites =>
      $$NotionPrerequisitesTableTableManager(_db, _db.notionPrerequisites);
  $$LearningEventsTableTableManager get learningEvents =>
      $$LearningEventsTableTableManager(_db, _db.learningEvents);
  $$EventNotionsTableTableManager get eventNotions =>
      $$EventNotionsTableTableManager(_db, _db.eventNotions);
  $$ExerciseAttemptsTableTableManager get exerciseAttempts =>
      $$ExerciseAttemptsTableTableManager(_db, _db.exerciseAttempts);
  $$ObservedErrorsTableTableManager get observedErrors =>
      $$ObservedErrorsTableTableManager(_db, _db.observedErrors);
  $$OfferedHintsTableTableManager get offeredHints =>
      $$OfferedHintsTableTableManager(_db, _db.offeredHints);
}
