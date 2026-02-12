import 'package:sqflite/sqflite.dart';
import '../repositories/database_helper.dart';
import 'supabase.dart';

class SyncService {
  Future<void> sync() async {
    try {
      print('[SYNC] Starting sync...');

      // PULL first (get data from cloud)
      print('[SYNC] Pulling from cloud...');
      await _pullFromCloud();
      print('[SYNC] Pull completed');

      // PUSH second (send local changes to cloud)
      print('[SYNC] Pushing to cloud...');
      await _pushToCloud();
      print('[SYNC] Push completed');

      // PUSH deletions
      print('[SYNC] Pushing deletions...');
      await _pushDeletions();
      print('[SYNC] Deletions completed');

      print('[SYNC] Sync finished successfully');
    } catch (e) {
      print('[SYNC] Sync error: $e');
      throw Exception('Sync failed: $e');
    }
  }

  // PULL: Download data from Supabase to local SQLite
  Future<void> _pullFromCloud() async {
    final db = await DatabaseHelper.instance.database;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Pull categories
    await _pullCategories(db, userId);

    // Pull transactions
    await _pullTransactions(db, userId);

    // Pull recurring configs
    await _pullRecurringConfigs(db, userId);
  }

  Future<void> _pullCategories(Database db, String userId) async {
    final cloudCategories = await supabase
        .from('categories')
        .select()
        .eq('user_id', userId);

    print('[SYNC] Pulling ${cloudCategories.length} categories from cloud');

    for (var cloudCat in cloudCategories) {
      final cloudId = cloudCat['id'] as String;
      final cloudUpdatedAt = DateTime.parse(cloudCat['updated_at'] as String);

      // Check if exists in local
      final localCats = await db.query(
        'categories',
        where: 'cloud_id = ?',
        whereArgs: [cloudId],
      );

      if (localCats.isEmpty) {
        // Insert new from cloud
        print('[SYNC] Inserting category: ${cloudCat['name']}');
        await db.insert('categories', {
          'id': cloudCat['id'],
          'cloud_id': cloudId,
          'name': cloudCat['name'],
          'type': cloudCat['type'],
          'icon': cloudCat['icon'],
          'color': cloudCat['color'],
          'synced': 1,
          'created_at': cloudCat['created_at'],
          'updated_at': cloudCat['updated_at'],
        });
      } else {
        // Check conflict: compare updated_at
        final localCat = localCats.first;
        final localUpdatedAt = DateTime.parse(localCat['updated_at'] as String);

        if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
          // Cloud is newer, update local
          await db.update(
            'categories',
            {
              'name': cloudCat['name'],
              'type': cloudCat['type'],
              'icon': cloudCat['icon'],
              'color': cloudCat['color'],
              'synced': 1,
              'updated_at': cloudCat['updated_at'],
            },
            where: 'cloud_id = ?',
            whereArgs: [cloudId],
          );
        }
        // If local is newer, will be pushed later in _pushToCloud
      }
    }
  }

  Future<void> _pullTransactions(Database db, String userId) async {
    final cloudTransactions = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId);

    for (var cloudTx in cloudTransactions) {
      final cloudId = cloudTx['id'] as String;
      final cloudUpdatedAt = DateTime.parse(cloudTx['updated_at'] as String);

      final localTxs = await db.query(
        'transactions',
        where: 'cloud_id = ?',
        whereArgs: [cloudId],
      );

      if (localTxs.isEmpty) {
        // Map cloud category_id to local category id
        String? localCategoryId;
        if (cloudTx['category_id'] != null) {
          final cloudCatId = cloudTx['category_id'] as String;
          final localCats = await db.query(
            'categories',
            where: 'cloud_id = ?',
            whereArgs: [cloudCatId],
          );
          if (localCats.isNotEmpty) {
            localCategoryId = localCats.first['id'] as String;
          }
        }

        await db.insert('transactions', {
          'id': cloudTx['id'],
          'cloud_id': cloudId,
          'category_id': localCategoryId,
          'recurring_config_id': cloudTx['recurring_config_id'],
          'amount': cloudTx['amount'],
          'formula': cloudTx['formula'],
          'note': cloudTx['note'],
          'type': cloudTx['type'],
          'synced': 1,
          'created_at': cloudTx['created_at'],
          'updated_at': cloudTx['updated_at'],
        });
      } else {
        final localTx = localTxs.first;
        final localUpdatedAt = DateTime.parse(localTx['updated_at'] as String);

        if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
          String? localCategoryId;
          if (cloudTx['category_id'] != null) {
            final cloudCatId = cloudTx['category_id'] as String;
            final localCats = await db.query(
              'categories',
              where: 'cloud_id = ?',
              whereArgs: [cloudCatId],
            );
            if (localCats.isNotEmpty) {
              localCategoryId = localCats.first['id'] as String;
            }
          }

          await db.update(
            'transactions',
            {
              'category_id': localCategoryId,
              'recurring_config_id': cloudTx['recurring_config_id'],
              'amount': cloudTx['amount'],
              'formula': cloudTx['formula'],
              'note': cloudTx['note'],
              'type': cloudTx['type'],
              'synced': 1,
              'updated_at': cloudTx['updated_at'],
            },
            where: 'cloud_id = ?',
            whereArgs: [cloudId],
          );
        }
      }
    }
  }

  Future<void> _pullRecurringConfigs(Database db, String userId) async {
    final cloudConfigs = await supabase
        .from('recurring_configs')
        .select()
        .eq('user_id', userId);

    for (var cloudConfig in cloudConfigs) {
      final cloudId = cloudConfig['id'] as String;
      final cloudUpdatedAt = DateTime.parse(cloudConfig['updated_at'] as String);

      final localConfigs = await db.query(
        'recurring_configs',
        where: 'cloud_id = ?',
        whereArgs: [cloudId],
      );

      if (localConfigs.isEmpty) {
        String? localCategoryId;
        if (cloudConfig['category_id'] != null) {
          final cloudCatId = cloudConfig['category_id'] as String;
          final localCats = await db.query(
            'categories',
            where: 'cloud_id = ?',
            whereArgs: [cloudCatId],
          );
          if (localCats.isNotEmpty) {
            localCategoryId = localCats.first['id'] as String;
          }
        }

        await db.insert('recurring_configs', {
          'id': cloudConfig['id'],
          'cloud_id': cloudId,
          'category_id': localCategoryId,
          'name': cloudConfig['name'],
          'amount': cloudConfig['amount'],
          'type': cloudConfig['type'],
          'frequency': cloudConfig['frequency'],
          'interval': cloudConfig['interval'],
          'day_of_week': cloudConfig['day_of_week'],
          'day_of_month': cloudConfig['day_of_month'],
          'next_run': cloudConfig['next_run'],
          'is_active': cloudConfig['is_active'] ? 1 : 0,
          'synced': 1,
          'created_at': cloudConfig['created_at'],
          'updated_at': cloudConfig['updated_at'],
        });
      } else {
        final localConfig = localConfigs.first;
        final localUpdatedAt = DateTime.parse(localConfig['updated_at'] as String);

        if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
          String? localCategoryId;
          if (cloudConfig['category_id'] != null) {
            final cloudCatId = cloudConfig['category_id'] as String;
            final localCats = await db.query(
              'categories',
              where: 'cloud_id = ?',
              whereArgs: [cloudCatId],
            );
            if (localCats.isNotEmpty) {
              localCategoryId = localCats.first['id'] as String;
            }
          }

          await db.update(
            'recurring_configs',
            {
              'category_id': localCategoryId,
              'name': cloudConfig['name'],
              'amount': cloudConfig['amount'],
              'type': cloudConfig['type'],
              'frequency': cloudConfig['frequency'],
              'interval': cloudConfig['interval'],
              'day_of_week': cloudConfig['day_of_week'],
              'day_of_month': cloudConfig['day_of_month'],
              'next_run': cloudConfig['next_run'],
              'is_active': cloudConfig['is_active'] ? 1 : 0,
              'synced': 1,
              'updated_at': cloudConfig['updated_at'],
            },
            where: 'cloud_id = ?',
            whereArgs: [cloudId],
          );
        }
      }
    }
  }

  // PUSH: Upload local changes to Supabase
  Future<void> _pushToCloud() async {
    final db = await DatabaseHelper.instance.database;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Push unsynced categories
    await _pushCategories(db, userId);

    // Push unsynced transactions
    await _pushTransactions(db, userId);

    // Push unsynced recurring configs
    await _pushRecurringConfigs(db, userId);
  }

  Future<void> _pushCategories(Database db, String userId) async {
    final unsyncedCategories = await db.query(
      'categories',
      where: 'synced = 0',
    );

    for (var localCat in unsyncedCategories) {
      final cloudId = localCat['cloud_id'] as String?;

      if (cloudId == null) {
        // New item, insert to cloud
        final inserted = await supabase.from('categories').insert({
          'user_id': userId,
          'name': localCat['name'],
          'type': localCat['type'],
          'icon': localCat['icon'],
          'color': localCat['color'],
          'created_at': localCat['created_at'],
          'updated_at': localCat['updated_at'],
        }).select().single();

        // Update local with cloud_id
        await db.update(
          'categories',
          {
            'cloud_id': inserted['id'],
            'synced': 1,
          },
          where: 'id = ?',
          whereArgs: [localCat['id']],
        );
      } else {
        // Update existing in cloud
        await supabase.from('categories').update({
          'name': localCat['name'],
          'type': localCat['type'],
          'icon': localCat['icon'],
          'color': localCat['color'],
          'updated_at': localCat['updated_at'],
        }).eq('id', cloudId);

        // Mark as synced
        await db.update(
          'categories',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [localCat['id']],
        );
      }
    }
  }

  Future<void> _pushTransactions(Database db, String userId) async {
    final unsyncedTransactions = await db.query(
      'transactions',
      where: 'synced = 0',
    );

    for (var localTx in unsyncedTransactions) {
      final cloudId = localTx['cloud_id'] as String?;

      // Get cloud category_id from local category_id
      String? cloudCategoryId;
      if (localTx['category_id'] != null) {
        final localCatId = localTx['category_id'] as String;
        final localCats = await db.query(
          'categories',
          where: 'id = ?',
          whereArgs: [localCatId],
        );
        if (localCats.isNotEmpty) {
          cloudCategoryId = localCats.first['cloud_id'] as String?;
        }
      }

      if (cloudId == null) {
        final inserted = await supabase.from('transactions').insert({
          'user_id': userId,
          'category_id': cloudCategoryId,
          'recurring_config_id': localTx['recurring_config_id'],
          'amount': localTx['amount'],
          'formula': localTx['formula'],
          'note': localTx['note'],
          'type': localTx['type'],
          'created_at': localTx['created_at'],
          'updated_at': localTx['updated_at'],
        }).select().single();

        await db.update(
          'transactions',
          {
            'cloud_id': inserted['id'],
            'synced': 1,
          },
          where: 'id = ?',
          whereArgs: [localTx['id']],
        );
      } else {
        await supabase.from('transactions').update({
          'category_id': cloudCategoryId,
          'recurring_config_id': localTx['recurring_config_id'],
          'amount': localTx['amount'],
          'formula': localTx['formula'],
          'note': localTx['note'],
          'type': localTx['type'],
          'updated_at': localTx['updated_at'],
        }).eq('id', cloudId);

        await db.update(
          'transactions',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [localTx['id']],
        );
      }
    }
  }

  Future<void> _pushRecurringConfigs(Database db, String userId) async {
    final unsyncedConfigs = await db.query(
      'recurring_configs',
      where: 'synced = 0',
    );

    for (var localConfig in unsyncedConfigs) {
      final cloudId = localConfig['cloud_id'] as String?;

      String? cloudCategoryId;
      if (localConfig['category_id'] != null) {
        final localCatId = localConfig['category_id'] as String;
        final localCats = await db.query(
          'categories',
          where: 'id = ?',
          whereArgs: [localCatId],
        );
        if (localCats.isNotEmpty) {
          cloudCategoryId = localCats.first['cloud_id'] as String?;
        }
      }

      if (cloudId == null) {
        final inserted = await supabase.from('recurring_configs').insert({
          'user_id': userId,
          'category_id': cloudCategoryId,
          'name': localConfig['name'],
          'amount': localConfig['amount'],
          'type': localConfig['type'],
          'frequency': localConfig['frequency'],
          'interval': localConfig['interval'],
          'day_of_week': localConfig['day_of_week'],
          'day_of_month': localConfig['day_of_month'],
          'next_run': localConfig['next_run'],
          'is_active': localConfig['is_active'] == 1,
          'created_at': localConfig['created_at'],
          'updated_at': localConfig['updated_at'],
        }).select().single();

        await db.update(
          'recurring_configs',
          {
            'cloud_id': inserted['id'],
            'synced': 1,
          },
          where: 'id = ?',
          whereArgs: [localConfig['id']],
        );
      } else {
        await supabase.from('recurring_configs').update({
          'category_id': cloudCategoryId,
          'name': localConfig['name'],
          'amount': localConfig['amount'],
          'type': localConfig['type'],
          'frequency': localConfig['frequency'],
          'interval': localConfig['interval'],
          'day_of_week': localConfig['day_of_week'],
          'day_of_month': localConfig['day_of_month'],
          'next_run': localConfig['next_run'],
          'is_active': localConfig['is_active'] == 1,
          'updated_at': localConfig['updated_at'],
        }).eq('id', cloudId);

        await db.update(
          'recurring_configs',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [localConfig['id']],
        );
      }
    }
  }

  // PUSH deletions from pending_deletions table
  Future<void> _pushDeletions() async {
    final db = await DatabaseHelper.instance.database;

    final pendingDeletions = await db.query('pending_deletions');

    for (var deletion in pendingDeletions) {
      final cloudId = deletion['cloud_id'] as String;
      final tableName = deletion['table_name'] as String;

      try {
        await supabase.from(tableName).delete().eq('id', cloudId);

        // Remove from pending_deletions after successful delete
        await db.delete(
          'pending_deletions',
          where: 'id = ?',
          whereArgs: [deletion['id']],
        );
      } catch (e) {
        // If delete fails, keep in pending_deletions for retry
        continue;
      }
    }
  }
}
