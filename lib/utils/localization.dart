class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'categories': 'Categories',
      'recurring': 'Recurring',
      'settings': 'Settings',

      // Dashboard
      'income': 'Income',
      'expense': 'Expense',
      'monthly_budget': 'Monthly Budget',
      'budget_not_set': 'Budget not set',
      'copy_previous_month_budget': "Copy previous month's budget",
      'copy_budget_success': 'Copied budget from previous month successfully',
      'no_budget_this_month': 'No budget set for this month',
      'set_budget_for_month': 'Set budget for this month',
      'select_month_year': 'Select Month & Year',
      'category_budgets': 'Category Budgets',
      'total_monthly_budget': 'Total Monthly Budget',
      'percent_used': '% used',
      'total_transactions': 'Transactions',
      'current_month': 'Current Month',
      'balance': 'Balance',
      'recent_transactions': 'Recent Transactions',
      'view_all': 'View All',
      'income_by_category': 'Income by Category',
      'expense_by_category': 'Expense by Category',
      'no_data': 'No data',
      'income_vs_expense': 'Income vs Expense',
      'spending_trend': 'Income & Expense Trend',
      'select_month': 'Month',
      'select_year': 'Year',
      '3_months': '3 months',
      '6_months': '6 months',
      '1_year': '1 year',
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dec',

      // Transactions
      'no_transactions': 'No transactions yet',
      'add_transaction': 'Add Transaction',
      'add_more': 'Add New Transaction',
      'save_all': 'Save',
      'type': 'Type',
      'amount': 'Amount',
      'formula': 'Formula',
      'category': 'Category',
      'note': 'Note',
      'no_category': 'No category',
      'delete_transaction': 'Delete Transaction',
      'delete_transaction_confirm':
          'Are you sure you want to delete this transaction?',
      'transaction_deleted': 'Transaction deleted',
      'transaction_created': 'Transactions created',
      'fill_all_fields': 'Please fill amount for all items',
      'item': 'Item',
      'transaction': 'Transaction',
      'optional': 'optional',
      'income_plus': 'Income (+)',
      'expense_minus': 'Expense (-)',
      'long_press_hint': 'Long press an item for more options',
      'transaction_date': 'Transaction Date',
      'created_at': 'Created At',
      'updated_at': 'Updated At',
      'tx_date_short': 'Tx',
      'created_at_short': 'Created',
      'updated_at_short': 'Updated',
      'original_date': 'Original Date',

      // Filter
      'filter': 'Filter',
      'filter_transactions': 'Filter Transactions',
      'time': 'Time',
      'all': 'All',
      'this_month': 'This Month',
      'last_month': 'Last Month',
      'last_3_months': 'Last 3 Months',
      'custom_range': 'Custom Range',
      'all_types': 'All Types',
      'all_categories': 'All Categories',
      'amount_range': 'Amount Range',
      'min_amount': 'Min Amount',
      'max_amount': 'Max Amount',
      'clear_all': 'Clear All',
      'apply': 'Apply',
      'from_date': 'From Date',
      'to_date': 'To Date',
      'active_filters': 'Active Filters',
      'load_more': 'Load More',
      'select_multiple': 'Select Multiple',

      // Categories
      'no_categories': 'No categories yet',
      'no_categories_warning':
          'No categories yet. Please create categories to get started.',
      'add_category': 'Add Category',
      'edit_category': 'Edit Category',
      'delete_category': 'Delete Category',
      'category_name': 'Category name',
      'delete_category_confirm': 'Are you sure you want to delete',
      'category_added': 'Category added',
      'category_updated': 'Category updated',
      'category_deleted': 'Category deleted',

      // Recurring
      'recurring_transactions': 'Recurring Transactions',
      'no_recurring': 'No recurring transactions yet',
      'add_recurring': 'Add Recurring',
      'edit_recurring': 'Edit Recurring',
      'delete_recurring': 'Delete Recurring Transaction',
      'delete_recurring_confirm': 'Are you sure you want to delete',
      'recurring_deleted': 'Recurring transaction deleted',
      'recurring_created': 'Recurring transaction created',
      'recurring_updated': 'Recurring transaction updated',
      'run_now': 'Run Now',
      'run_now_confirm': 'Execute this recurring transaction immediately?',
      'transaction_triggered': 'Transaction created',
      'name': 'Name',
      'frequency': 'Frequency',
      'interval': 'Interval',
      'day_of_week': 'Day of Week',
      'day_of_month': 'Day of Month (1-31)',
      'next_run': 'Next run',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'by_day': 'By day',
      'by_week': 'By week',
      'by_month': 'By month',
      'days': 'days',
      'week': 'week',
      'weeks': 'weeks',
      'month': 'month',
      'months': 'months',
      'every': 'Every',
      'on': 'on',
      'day': 'day',
      'sunday': 'Sunday',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',

      // Settings
      'monthly_budget_setting': 'Monthly Budget',
      'currency': 'Currency',
      'language': 'Language',
      'save': 'Save',
      'settings_saved': 'Settings saved',
      'vietnamese': 'Vietnamese',
      'english': 'English',
      'chinese': 'Chinese',
      'about': 'About',
      'app_description':
          'A simple and intuitive personal finance management app.',

      // Account
      'account': 'Account',
      'sync_data': 'Sync Data',
      'syncing': 'Syncing...',
      'sync_success': 'Sync successful',
      'sync_failed': 'Sync failed',
      'logout': 'Logout',
      'logout_confirm':
          'Are you sure you want to logout?\n\nData will be synced to cloud before logout.\n\nNote: Internet connection is required for next login.',
      'syncing_data': 'Syncing data...',
      'logout_error': 'Logout error',
      'loading_data': 'Loading data...',
      'internet_required_for_login':
          'Note: Internet connection is required for login',

      // Auth
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'register': 'Register',
      'dont_have_account': 'Don\'t have an account?',
      'create_new_account': 'Create New Account',
      'register_to_sync': 'Register to sync data across multiple devices',
      'confirm_password': 'Confirm Password',
      'app_tagline': 'Simple Money Management',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'reset_password_instruction':
          'Enter your email to receive password reset instructions',
      'send_reset_link': 'Send Reset Link',
      'reset_link_sent':
          'Password reset link sent!\n\nPlease check your email.',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'password_changed': 'Password changed successfully',
      'change_password_failed': 'Failed to change password',
      'please_enter_current_password': 'Please enter current password',
      'please_enter_new_password': 'Please enter new password',
      'new_passwords_not_match': 'New passwords do not match',
      'new_password_must_be_different':
          'New password must be different from current password',

      // Auth Validation
      'please_enter_email': 'Please enter email',
      'invalid_email': 'Invalid email',
      'please_enter_password': 'Please enter password',
      'password_min_6': 'Password must be at least 6 characters',
      'password_min_8': 'Password must be at least 8 characters',
      'password_helper':
          'Minimum 8 characters, with uppercase, lowercase, number and special character',
      'password_need_uppercase':
          'Password must have at least 1 uppercase letter',
      'password_need_lowercase':
          'Password must have at least 1 lowercase letter',
      'password_need_number': 'Password must have at least 1 number',
      'password_need_special':
          'Password must have at least 1 special character',
      'please_confirm_password': 'Please confirm password',
      'passwords_not_match': 'Passwords do not match',

      // Auth Errors
      'login_failed': 'Login failed',
      'invalid_credentials': 'Invalid email or password',
      'email_not_confirmed':
          'Please confirm your email before logging in.\nCheck your inbox.',
      'network_error': 'Network error. Please check your internet connection.',
      'register_failed': 'Registration failed',
      'email_already_registered':
          'This email is already registered.\nPlease use another email or login.',
      'password_too_weak':
          'Password is too weak.\nPlease use a stronger password.',
      'system_error': 'System error.\nPlease try again later.',
      'register_success_confirm':
          'Registration successful!\n\nPlease check your email to confirm your account before logging in.',
      'register_success': 'Registration successful! You can login now.',

      // Common
      'cancel': 'Cancel',
      'add': 'Add',
      'edit': 'Edit',
      'delete': 'Delete',
      'error': 'Error',
      'category_optional': 'Category (optional)',
      'done': 'Done',

      // Calculator
      'please_enter_amount': 'Please enter an amount',
      'amount_cannot_negative': 'Amount cannot be negative',
      'invalid_formula': 'Invalid formula',
      'currency_converter': 'Currency Converter',
      'currency_converter_hint': 'Convert foreign currency to your main currency',
      'select_currency': 'Select Currency',
      'please_enter_amount_first': 'Please enter amount first',
      'invalid_amount': 'Invalid amount',
      'cannot_load_settings': 'Cannot load settings',
      'failed_to_fetch_rate': 'Failed to fetch exchange rate',

      // Default Categories
      'cat_salary': 'Salary',
      'cat_bonus': 'Bonus',
      'cat_investment': 'Investment',
      'cat_other_income': 'Other Income',
      'cat_food': 'Food & Dining',
      'cat_transport': 'Transportation',
      'cat_shopping': 'Shopping',
      'cat_entertainment': 'Entertainment',
      'cat_bills': 'Bills & Utilities',
      'cat_healthcare': 'Healthcare',
      'cat_other_expense': 'Other',

      // Ad-Free
      'watch_ad_remove_ads': 'Watch ad to remove ads',
      'ad_free_active': 'Ad-Free Active',
      'remove_ads_title': 'Remove Ads',
      'watch_ad_prompt': 'Watch a video ad to remove all ads for',
      'ad_free_status': 'You are ad-free for',
      'watch_ad_button': 'Watch Ad',
      'ad_free_granted': 'Ad-free for',
      'hours': 'hours',
      'minutes': 'minutes',
      'seconds': 'seconds',

      // Mock & Reset Data
      'data_and_testing': 'Data & Testing',
      'generate_mock_data': 'Generate Mock Data',
      'generate_mock_data_desc':
          'Generate 100+ sample transactions across 6 months (Mar - Aug)',
      'generate_mock_data_confirm':
          'Generate rich sample data from March to August 2026?',
      'mock_data_generated': 'Sample data generated successfully!',
      'reset_all_data': 'Reset All Data',
      'reset_all_data_desc': 'Delete all transactions, categories, and loans',
      'reset_all_data_confirm':
          'This action will delete all transactions, categories, and loans. Cannot be undone.\n\nType "delete" to confirm.',
      'reset_success': 'All data has been reset.',

      // Export & Backup
      'export_backup': 'Export & Backup',
      'export_backup_desc': 'Export Excel, CSV, PDF & JSON backup',
      'export_reports': 'Export Reports',
      'backup_restore': 'Backup & Restore',
      'export_excel': 'Excel (.xlsx)',
      'export_excel_desc': 'Multi-sheet workbook with transactions, budgets, and loans',
      'export_csv': 'CSV (.csv)',
      'export_csv_desc': 'Universal format with UTF-8 BOM encoding',
      'export_pdf': 'PDF Report (.pdf)',
      'export_pdf_desc': 'Printable financial report with summaries and charts',
      'create_backup': 'Create Backup',
      'create_backup_desc': 'Full snapshot of all database records and settings',
      'restore_backup': 'Restore Data',
      'restore_backup_desc': 'Select a previously saved backup file to restore',
      'restore_backup_hint': 'Select a previously saved .json backup file',
      'export_format': 'Export Format',
      'export_action': 'Export File',
      'export_time_range': 'Export Time Range',
      'export_success': 'Export completed successfully!',
      'export_failed': 'Export failed',
      'backup_created': 'Backup created successfully!',
      'restore_success': 'Data restored successfully!',
      'restore_failed': 'Restore failed',
      'import_preview_title': 'Restore Preview',
      'import_overwrite': 'Overwrite All Data',
      'import_merge': 'Merge Data',
      'import_invalid_file': 'Invalid backup file',
      'total_categories_count': 'Categories',
      'total_transactions_count': 'Transactions',
      'total_budgets_count': 'Monthly Budgets',
      'total_loans_count': 'Loans & Debts',
      'total_recurring_count': 'Recurring Transactions',
      'exporting_data': 'Exporting data...',
      'restoring_data': 'Restoring data...',

      // Saving Goals
      'saving_goals': 'Saving Goals',
      'add_saving_goal': 'Add Saving Goal',
      'edit_saving_goal': 'Edit Saving Goal',
      'delete_saving_goal': 'Delete Goal',
      'delete_saving_goal_confirm':
          'Are you sure you want to delete this saving goal? All history logs will also be deleted.',
      'goal_name': 'Goal Name',
      'target_amount': 'Target Amount',
      'target_date': 'Target Date',
      'optional_deadline': 'Optional Deadline',
      'current_saved': 'Saved',
      'remaining_to_save': 'Remaining',
      'deposit': 'Deposit',
      'withdraw': 'Withdraw',
      'deposit_to_goal': 'Deposit Funds',
      'withdraw_from_goal': 'Withdraw Funds',
      'deposit_success': 'Deposit successful!',
      'withdraw_success': 'Withdrawal successful!',
      'goal_created': 'Saving goal created!',
      'goal_updated': 'Saving goal updated!',
      'goal_deleted': 'Saving goal deleted!',
      'goal_completed': 'Completed',
      'goal_in_progress': 'In Progress',
      'all_goals': 'All Goals',
      'total_target': 'Total Target',
      'total_saved': 'Total Saved',
      'no_saving_goals': 'No saving goals yet',
      'no_saving_goals_desc':
          'Create your first saving goal to track your dreams',
      'history_logs': 'History Logs',
      'no_history_logs': 'No deposit or withdrawal history yet',
    },
    'zh': {
      // Navigation
      'dashboard': '仪表板',
      'transactions': '交易',
      'categories': '类别',
      'recurring': '定期',
      'settings': '设置',

      // Dashboard
      'income': '收入',
      'expense': '支出',
      'monthly_budget': '月度预算',
      'budget_not_set': '未设置预算',
      'copy_previous_month_budget': '复制上月预算',
      'copy_budget_success': '已成功复制上月预算',
      'no_budget_this_month': '本月未设置预算',
      'set_budget_for_month': '设置本月预算',
      'select_month_year': '选择月份和年份',
      'category_budgets': '分类预算',
      'total_monthly_budget': '总月度预算',
      'percent_used': '% 已用',
      'total_transactions': '交易',
      'current_month': '本月',
      'balance': '余额',
      'recent_transactions': '最近交易',
      'view_all': '查看全部',
      'income_by_category': '按类别分类的收入',
      'expense_by_category': '按类别分类的支出',
      'no_data': '无数据',
      'income_vs_expense': '收入 vs 支出',
      'spending_trend': '收入与支出趋势',
      'select_month': '月份',
      'select_year': '年份',
      '3_months': '3 个月',
      '6_months': '6 个月',
      '1_year': '1 年',
      'jan': '1月',
      'feb': '2月',
      'mar': '3月',
      'apr': '4月',
      'may': '5月',
      'jun': '6月',
      'jul': '7月',
      'aug': '8月',
      'sep': '9月',
      'oct': '10月',
      'nov': '11月',
      'dec': '12月',

      // Transactions
      'no_transactions': '还没有交易',
      'add_transaction': '添加交易',
      'add_more': '添加新交易',
      'save_all': '保存',
      'type': '类型',
      'amount': '金额',
      'formula': '公式',
      'category': '类别',
      'note': '备注',
      'no_category': '无类别',
      'delete_transaction': '删除交易',
      'delete_transaction_confirm': '您确定要删除此交易吗？',
      'transaction_deleted': '交易已删除',
      'transaction_created': '交易已创建',
      'fill_all_fields': '请填写所有项目的金额',
      'item': '项目',
      'transaction': '交易',
      'optional': '可选',
      'income_plus': '收入 (+)',
      'expense_minus': '支出 (-)',
      'long_press_hint': '长按项目以获取更多选项',
      'transaction_date': '交易日期',
      'created_at': '创建时间',
      'updated_at': '更新时间',
      'tx_date_short': '交易',
      'created_at_short': '创建',
      'updated_at_short': '更新',
      'original_date': '原日期',

      // Filter
      'filter': '筛选',
      'filter_transactions': '筛选交易',
      'time': '时间',
      'all': '全部',
      'this_month': '本月',
      'last_month': '上月',
      'last_3_months': '最近 3 个月',
      'custom_range': '自定义范围',
      'all_types': '所有类型',
      'all_categories': '所有类别',
      'amount_range': '金额范围',
      'min_amount': '最小金额',
      'max_amount': '最大金额',
      'clear_all': '清除全部',
      'apply': '应用',
      'from_date': '起始日期',
      'to_date': '结束日期',
      'active_filters': '活动筛选',
      'load_more': '加载更多',
      'select_multiple': '选择多个',

      // Categories
      'no_categories': '还没有类别',
      'no_categories_warning': '还没有类别。请创建类别以开始使用。',
      'add_category': '添加类别',
      'edit_category': '编辑类别',
      'delete_category': '删除类别',
      'category_name': '类别名称',
      'delete_category_confirm': '您确定要删除',
      'category_added': '类别已添加',
      'category_updated': '类别已更新',
      'category_deleted': '类别已删除',

      // Recurring
      'recurring_transactions': '定期交易',
      'no_recurring': '还没有定期交易',
      'add_recurring': '添加定期',
      'edit_recurring': '编辑定期',
      'delete_recurring': '删除定期交易',
      'delete_recurring_confirm': '您确定要删除',
      'recurring_deleted': '定期交易已删除',
      'recurring_created': '定期交易已创建',
      'recurring_updated': '定期交易已更新',
      'run_now': '立即运行',
      'run_now_confirm': '立即执行此定期交易？',
      'transaction_triggered': '交易已创建',
      'name': '名称',
      'frequency': '频率',
      'interval': '间隔',
      'day_of_week': '星期几',
      'day_of_month': '每月第几天 (1-31)',
      'next_run': '下次运行',
      'daily': '每日',
      'weekly': '每周',
      'monthly': '每月',
      'by_day': '按天',
      'by_week': '按周',
      'by_month': '按月',
      'days': '天',
      'week': '周',
      'weeks': '周',
      'month': '月',
      'months': '月',
      'every': '每',
      'on': '在',
      'day': '天',
      'sunday': '星期日',
      'monday': '星期一',
      'tuesday': '星期二',
      'wednesday': '星期三',
      'thursday': '星期四',
      'friday': '星期五',
      'saturday': '星期六',

      // Settings
      'monthly_budget_setting': '月度预算',
      'currency': '货币',
      'language': '语言',
      'save': '保存',
      'settings_saved': '设置已保存',
      'vietnamese': '越南语',
      'english': '英语',
      'chinese': '中文',
      'about': '关于',
      'app_description': '一个简单直观的个人财务管理应用。',

      // Account
      'account': '账户',
      'sync_data': '同步数据',
      'syncing': '同步中...',
      'sync_success': '同步成功',
      'sync_failed': '同步失败',
      'logout': '登出',
      'logout_confirm': '您确定要登出吗？\n\n数据将在登出前同步到云端。\n\n注意：下次登录需要互联网连接。',
      'syncing_data': '正在同步数据...',
      'logout_error': '登出错误',
      'loading_data': '加载数据中...',
      'internet_required_for_login': '注意：登录需要互联网连接',

      // Auth
      'email': '电子邮件',
      'password': '密码',
      'login': '登录',
      'register': '注册',
      'dont_have_account': '还没有账户？',
      'create_new_account': '创建新账户',
      'register_to_sync': '注册以在多个设备间同步数据',
      'confirm_password': '确认密码',
      'app_tagline': '简单的资金管理',
      'forgot_password': '忘记密码？',
      'reset_password': '重置密码',
      'reset_password_instruction': '输入您的电子邮件以接收密码重置说明',
      'send_reset_link': '发送重置链接',
      'reset_link_sent': '密码重置链接已发送！\n\n请检查您的电子邮件。',
      'change_password': '更改密码',
      'current_password': '当前密码',
      'new_password': '新密码',
      'confirm_new_password': '确认新密码',
      'password_changed': '密码更改成功',
      'change_password_failed': '密码更改失败',
      'please_enter_current_password': '请输入当前密码',
      'please_enter_new_password': '请输入新密码',
      'new_passwords_not_match': '新密码不匹配',
      'new_password_must_be_different': '新密码必须与当前密码不同',

      // Auth Validation
      'please_enter_email': '请输入电子邮件',
      'invalid_email': '无效的电子邮件',
      'please_enter_password': '请输入密码',
      'password_min_6': '密码必须至少 6 个字符',
      'password_min_8': '密码必须至少 8 个字符',
      'password_helper': '至少 8 个字符，包含大写、小写、数字和特殊字符',
      'password_need_uppercase': '密码必须至少包含 1 个大写字母',
      'password_need_lowercase': '密码必须至少包含 1 个小写字母',
      'password_need_number': '密码必须至少包含 1 个数字',
      'password_need_special': '密码必须至少包含 1 个特殊字符',
      'please_confirm_password': '请确认密码',
      'passwords_not_match': '密码不匹配',

      // Auth Errors
      'login_failed': '登录失败',
      'invalid_credentials': '无效的电子邮件或密码',
      'email_not_confirmed': '请在登录前确认您的电子邮件。\n请检查您的收件箱。',
      'network_error': '网络错误。请检查您的互联网连接。',
      'register_failed': '注册失败',
      'email_already_registered': '此电子邮件已被注册。\n请使用其他电子邮件或登录。',
      'password_too_weak': '密码太弱。\n请使用更强的密码。',
      'system_error': '系统错误。\n请稍后重试。',
      'register_success_confirm': '注册成功！\n\n请在登录前检查您的电子邮件以确认您的账户。',
      'register_success': '注册成功！您现在可以登录了。',

      // Common
      'cancel': '取消',
      'add': '添加',
      'edit': '编辑',
      'delete': '删除',
      'error': '错误',
      'category_optional': '类别（可选）',
      'done': '完成',

      // Calculator
      'please_enter_amount': '请输入金额',
      'amount_cannot_negative': '金额不能为负',
      'invalid_formula': '无效的公式',
      'currency_converter': '货币转换器',
      'currency_converter_hint': '输入外币，转换为主货币',
      'select_currency': '选择货币',
      'please_enter_amount_first': '请先输入金额',
      'invalid_amount': '无效金额',
      'cannot_load_settings': '无法加载设置',
      'failed_to_fetch_rate': '无法获取汇率',

      // Default Categories
      'cat_salary': '工资',
      'cat_bonus': '奖金',
      'cat_investment': '投资',
      'cat_other_income': '其他收入',
      'cat_food': '餐饮',
      'cat_transport': '交通',
      'cat_shopping': '购物',
      'cat_entertainment': '娱乐',
      'cat_bills': '账单与公用事业',
      'cat_healthcare': '医疗',
      'cat_other_expense': '其他',

      // Ad-Free
      'watch_ad_remove_ads': '观看广告以移除广告',
      'ad_free_active': '无广告已激活',
      'remove_ads_title': '移除广告',
      'watch_ad_prompt': '观看视频广告以移除所有广告',
      'ad_free_status': '您的无广告时间还有',
      'watch_ad_button': '观看广告',
      'ad_free_granted': '无广告时长',
      'hours': '小时',
      'minutes': '分钟',
      'seconds': '秒',

      // Mock & Reset Data
      'data_and_testing': '数据与测试',
      'generate_mock_data': '生成模拟数据',
      'generate_mock_data_desc': '生成6个月内的100多条模拟交易（3月至8月）',
      'generate_mock_data_confirm': '生成2026年3月至8月的丰富模拟数据？',
      'mock_data_generated': '模拟数据生成成功！',
      'reset_all_data': '重置所有数据',
      'reset_all_data_desc': '删除所有交易、分类和贷款',
      'reset_all_data_confirm':
          '此操作将删除所有交易、分类和贷款，无法撤消。\n\n输入 "delete" 以确认。',
      'reset_success': '所有数据已重置。',

      // Export & Backup
      'export_backup': '导出与备份',
      'export_backup_desc': '导出Excel、CSV、PDF和JSON备份',
      'export_reports': '导出报告',
      'backup_restore': '备份与恢复',
      'export_excel': 'Excel (.xlsx)',
      'export_excel_desc': '包含交易、预算和贷款的完整工作簿',
      'export_csv': 'CSV (.csv)',
      'export_csv_desc': '通用UTF-8 BOM编码格式',
      'export_pdf': 'PDF 报告 (.pdf)',
      'export_pdf_desc': '包含摘要和图表的可打印财务报表',
      'create_backup': '创建备份',
      'create_backup_desc': '所有数据库记录和设置的完整快照',
      'restore_backup': '恢复数据',
      'restore_backup_desc': '选择之前保存的备份文件进行恢复',
      'restore_backup_hint': '请选择之前保存的 .json 备份文件',
      'export_format': '导出格式',
      'export_action': '导出文件',
      'export_time_range': '导出时间范围',
      'export_success': '导出成功！',
      'export_failed': '导出失败',
      'backup_created': '备份创建成功！',
      'restore_success': '数据恢复成功！',
      'restore_failed': '恢复失败',
      'import_preview_title': '恢复预览',
      'import_overwrite': '覆盖所有数据',
      'import_merge': '合并数据',
      'import_invalid_file': '无效的备份文件',
      'total_categories_count': '类别',
      'total_transactions_count': '交易',
      'total_budgets_count': '月度预算',
      'total_loans_count': '贷款与债务',
      'total_recurring_count': '定期交易',
      'exporting_data': '正在导出数据...',
      'restoring_data': '正在恢复数据...',

      // Saving Goals
      'saving_goals': '储蓄目标',
      'add_saving_goal': '添加储蓄目标',
      'edit_saving_goal': '编辑储蓄目标',
      'delete_saving_goal': '删除目标',
      'delete_saving_goal_confirm': '您确定要删除此储蓄目标吗？所有存取款记录也将被删除。',
      'goal_name': '目标名称',
      'target_amount': '目标金额',
      'target_date': '目标日期',
      'optional_deadline': '截止日期（可选）',
      'current_saved': '已储蓄',
      'remaining_to_save': '剩余',
      'deposit': '存入',
      'withdraw': '取出',
      'deposit_to_goal': '存入储蓄金',
      'withdraw_from_goal': '取出储蓄金',
      'deposit_success': '存入成功！',
      'withdraw_success': '取出成功！',
      'goal_created': '目标创建成功！',
      'goal_updated': '目标已更新！',
      'goal_deleted': '目标已删除！',
      'goal_completed': '已完成',
      'goal_in_progress': '进行中',
      'all_goals': '所有目标',
      'total_target': '总目标',
      'total_saved': '已存总计',
      'no_saving_goals': '暂无储蓄目标',
      'no_saving_goals_desc': '创建您的第一个储蓄目标以追踪您的梦想',
      'history_logs': '存取记录',
      'no_history_logs': '暂无存取款记录',
    },
    'vi': {
      // Navigation
      'dashboard': 'Tổng quan',
      'transactions': 'Giao dịch',
      'categories': 'Danh mục',
      'recurring': 'Định kỳ',
      'settings': 'Cài đặt',

      // Dashboard
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'monthly_budget': 'Giới hạn tháng',
      'budget_not_set': 'Chưa đặt giới hạn',
      'copy_previous_month_budget': 'Sao chép ngân sách tháng trước',
      'copy_budget_success': 'Đã sao chép ngân sách từ tháng trước',
      'no_budget_this_month': 'Chưa đặt ngân sách cho tháng này',
      'set_budget_for_month': 'Đặt ngân sách cho tháng này',
      'select_month_year': 'Chọn tháng & năm',
      'category_budgets': 'Ngân sách danh mục',
      'total_monthly_budget': 'Tổng ngân sách tháng',
      'percent_used': '% đã dùng',
      'total_transactions': 'Giao dịch',
      'current_month': 'Tháng hiện tại',
      'balance': 'Số dư',
      'recent_transactions': 'Giao dịch gần đây',
      'view_all': 'Xem tất cả',
      'income_by_category': 'Thu nhập theo danh mục',
      'expense_by_category': 'Chi tiêu theo danh mục',
      'no_data': 'Không có dữ liệu',
      'income_vs_expense': 'Thu nhập vs Chi tiêu',
      'spending_trend': 'Xu hướng thu nhập và chi tiêu',
      'select_month': 'Tháng',
      'select_year': 'Năm',
      '3_months': '3 tháng',
      '6_months': '6 tháng',
      '1_year': '1 năm',
      'jan': 'Thg 1',
      'feb': 'Thg 2',
      'mar': 'Thg 3',
      'apr': 'Thg 4',
      'may': 'Thg 5',
      'jun': 'Thg 6',
      'jul': 'Thg 7',
      'aug': 'Thg 8',
      'sep': 'Thg 9',
      'oct': 'Thg 10',
      'nov': 'Thg 11',
      'dec': 'Thg 12',

      // Transactions
      'no_transactions': 'Chưa có giao dịch',
      'add_transaction': 'Thêm giao dịch',
      'add_more': 'Thêm giao dịch mới',
      'save_all': 'Lưu',
      'type': 'Loại',
      'amount': 'Số tiền',
      'formula': 'Công thức',
      'category': 'Danh mục',
      'note': 'Ghi chú',
      'no_category': 'Không có danh mục',
      'delete_transaction': 'Xóa giao dịch',
      'delete_transaction_confirm': 'Bạn chắc chắn muốn xóa giao dịch này?',
      'transaction_deleted': 'Đã xóa giao dịch',
      'transaction_created': 'Đã tạo giao dịch',
      'fill_all_fields': 'Vui lòng điền số tiền cho tất cả các mục',
      'item': 'Mục',
      'transaction': 'Giao dịch',
      'optional': 'tùy chọn',
      'income_plus': 'Thu nhập (+)',
      'expense_minus': 'Chi tiêu (-)',
      'long_press_hint': 'Nhấn giữ một mục để xem thêm tùy chọn',
      'transaction_date': 'Ngày giao dịch',
      'created_at': 'Ngày tạo',
      'updated_at': 'Ngày cập nhật',
      'tx_date_short': 'GD',
      'created_at_short': 'Tạo',
      'updated_at_short': 'CN',
      'original_date': 'Ngày gốc',

      // Filter
      'filter': 'Lọc',
      'filter_transactions': 'Lọc giao dịch',
      'time': 'Thời gian',
      'all': 'Tất cả',
      'this_month': 'Tháng này',
      'last_month': 'Tháng trước',
      'last_3_months': '3 tháng gần đây',
      'custom_range': 'Tùy chỉnh',
      'all_types': 'Tất cả loại',
      'all_categories': 'Tất cả danh mục',
      'amount_range': 'Khoảng số tiền',
      'min_amount': 'Số tiền tối thiểu',
      'max_amount': 'Số tiền tối đa',
      'clear_all': 'Xóa hết',
      'apply': 'Áp dụng',
      'from_date': 'Từ ngày',
      'to_date': 'Đến ngày',
      'active_filters': 'Bộ lọc đang dùng',
      'load_more': 'Tải thêm',
      'select_multiple': 'Chọn nhiều',

      // Categories
      'no_categories': 'Chưa có danh mục',
      'no_categories_warning':
          'Chưa có danh mục nào. Hãy tạo các danh mục của bạn.',
      'add_category': 'Thêm danh mục',
      'edit_category': 'Sửa danh mục',
      'delete_category': 'Xóa danh mục',
      'category_name': 'Tên danh mục',
      'delete_category_confirm': 'Bạn chắc chắn muốn xóa',
      'category_added': 'Đã thêm danh mục',
      'category_updated': 'Đã cập nhật danh mục',
      'category_deleted': 'Đã xóa danh mục',

      // Recurring
      'recurring_transactions': 'Giao dịch định kỳ',
      'no_recurring': 'Chưa có giao dịch định kỳ',
      'add_recurring': 'Thêm định kỳ',
      'edit_recurring': 'Sửa định kỳ',
      'delete_recurring': 'Xóa giao dịch định kỳ',
      'delete_recurring_confirm': 'Bạn chắc chắn muốn xóa',
      'recurring_deleted': 'Đã xóa giao dịch định kỳ',
      'recurring_created': 'Đã tạo giao dịch định kỳ',
      'recurring_updated': 'Đã cập nhật giao dịch định kỳ',
      'run_now': 'Chạy ngay',
      'run_now_confirm': 'Thực hiện giao dịch định kỳ này ngay lập tức?',
      'transaction_triggered': 'Đã tạo giao dịch',
      'name': 'Tên',
      'frequency': 'Tần suất',
      'interval': 'Khoảng cách',
      'day_of_week': 'Thứ trong tuần',
      'day_of_month': 'Ngày trong tháng (1-31)',
      'next_run': 'Lần chạy tiếp theo',
      'daily': 'Hàng ngày',
      'weekly': 'Hàng tuần',
      'monthly': 'Hàng tháng',
      'by_day': 'Theo ngày',
      'by_week': 'Theo tuần',
      'by_month': 'Theo tháng',
      'days': 'ngày',
      'week': 'tuần',
      'weeks': 'tuần',
      'month': 'tháng',
      'months': 'tháng',
      'every': 'Mỗi',
      'on': 'vào',
      'day': 'ngày',
      'sunday': 'Chủ nhật',
      'monday': 'Thứ 2',
      'tuesday': 'Thứ 3',
      'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5',
      'friday': 'Thứ 6',
      'saturday': 'Thứ 7',

      // Settings
      'monthly_budget_setting': 'Giới hạn tháng',
      'currency': 'Tiền tệ',
      'language': 'Ngôn ngữ',
      'save': 'Lưu',
      'settings_saved': 'Đã lưu cài đặt',
      'vietnamese': 'Tiếng Việt',
      'english': 'Tiếng Anh',
      'chinese': 'Tiếng Trung',
      'about': 'Giới thiệu',
      'app_description':
          'Ứng dụng quản lý tài chính cá nhân đơn giản và trực quan.',

      // Account
      'account': 'Tài khoản',
      'sync_data': 'Đồng bộ dữ liệu',
      'syncing': 'Đang đồng bộ...',
      'sync_success': 'Đồng bộ thành công',
      'sync_failed': 'Đồng bộ thất bại',
      'logout': 'Đăng xuất',
      'logout_confirm':
          'Bạn có chắc chắn muốn đăng xuất?\n\nDữ liệu sẽ được đồng bộ lên cloud trước khi đăng xuất.\n\nLưu ý: Lần đăng nhập tiếp theo cần có kết nối mạng.',
      'syncing_data': 'Đang đồng bộ dữ liệu...',
      'logout_error': 'Lỗi khi đăng xuất',
      'loading_data': 'Đang tải dữ liệu...',
      'internet_required_for_login':
          'Lưu ý: Cần có kết nối mạng để đăng nhập',

      // Auth
      'email': 'Email',
      'password': 'Mật khẩu',
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'dont_have_account': 'Chưa có tài khoản?',
      'create_new_account': 'Tạo tài khoản mới',
      'register_to_sync': 'Đăng ký để đồng bộ dữ liệu trên nhiều thiết bị',
      'confirm_password': 'Xác nhận mật khẩu',
      'app_tagline': 'Quản lý tài chính đơn giản',
      'forgot_password': 'Quên mật khẩu?',
      'reset_password': 'Đặt lại mật khẩu',
      'reset_password_instruction':
          'Nhập email của bạn để nhận hướng dẫn đặt lại mật khẩu',
      'send_reset_link': 'Gửi liên kết đặt lại',
      'reset_link_sent':
          'Đã gửi liên kết đặt lại mật khẩu!\n\nVui lòng kiểm tra email của bạn.',
      'change_password': 'Đổi mật khẩu',
      'current_password': 'Mật khẩu hiện tại',
      'new_password': 'Mật khẩu mới',
      'confirm_new_password': 'Xác nhận mật khẩu mới',
      'password_changed': 'Đổi mật khẩu thành công',
      'change_password_failed': 'Đổi mật khẩu thất bại',
      'please_enter_current_password': 'Vui lòng nhập mật khẩu hiện tại',
      'please_enter_new_password': 'Vui lòng nhập mật khẩu mới',
      'new_passwords_not_match': 'Mật khẩu mới không khớp',
      'new_password_must_be_different':
          'Mật khẩu mới phải khác với mật khẩu hiện tại',

      // Auth Validation
      'please_enter_email': 'Vui lòng nhập email',
      'invalid_email': 'Email không hợp lệ',
      'please_enter_password': 'Vui lòng nhập mật khẩu',
      'password_min_6': 'Mật khẩu phải có ít nhất 6 ký tự',
      'password_min_8': 'Mật khẩu phải có ít nhất 8 ký tự',
      'password_helper':
          'Tối thiểu 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt',
      'password_need_uppercase': 'Mật khẩu phải có ít nhất 1 chữ hoa',
      'password_need_lowercase': 'Mật khẩu phải có ít nhất 1 chữ thường',
      'password_need_number': 'Mật khẩu phải có ít nhất 1 chữ số',
      'password_need_special': 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt',
      'please_confirm_password': 'Vui lòng xác nhận mật khẩu',
      'passwords_not_match': 'Mật khẩu không khớp',

      // Auth Errors
      'login_failed': 'Đăng nhập thất bại',
      'invalid_credentials': 'Email hoặc mật khẩu không đúng',
      'email_not_confirmed':
          'Vui lòng xác nhận email trước khi đăng nhập.\nKiểm tra hộp thư của bạn.',
      'network_error': 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.',
      'register_failed': 'Đăng ký thất bại',
      'email_already_registered':
          'Email này đã được đăng ký.\nVui lòng sử dụng email khác hoặc đăng nhập.',
      'password_too_weak':
          'Mật khẩu quá yếu.\nVui lòng sử dụng mật khẩu mạnh hơn.',
      'system_error': 'Lỗi hệ thống.\nVui lòng thử lại sau.',
      'register_success_confirm':
          'Đăng ký thành công!\n\nVui lòng kiểm tra email để xác nhận tài khoản trước khi đăng nhập.',
      'register_success': 'Đăng ký thành công! Bạn có thể đăng nhập ngay.',

      // Common
      'cancel': 'Hủy',
      'add': 'Thêm',
      'edit': 'Sửa',
      'delete': 'Xóa',
      'error': 'Lỗi',
      'category_optional': 'Danh mục (tùy chọn)',
      'done': 'Xong',

      // Calculator
      'please_enter_amount': 'Vui lòng nhập số tiền',
      'amount_cannot_negative': 'Số tiền không thể âm',
      'invalid_formula': 'Công thức không hợp lệ',
      'currency_converter': 'Chuyển đổi tiền tệ',
      'currency_converter_hint': 'Nhập ngoại tệ, chuyển sang tiền chính',
      'select_currency': 'Chọn đơn vị tiền tệ',
      'please_enter_amount_first': 'Vui lòng nhập số tiền trước',
      'invalid_amount': 'Số tiền không hợp lệ',
      'cannot_load_settings': 'Không thể tải cài đặt',
      'failed_to_fetch_rate': 'Không thể lấy tỷ giá',

      // Default Categories
      'cat_salary': 'Lương',
      'cat_bonus': 'Thưởng',
      'cat_investment': 'Đầu tư',
      'cat_other_income': 'Thu nhập khác',
      'cat_food': 'Ăn uống',
      'cat_transport': 'Đi lại',
      'cat_shopping': 'Mua sắm',
      'cat_entertainment': 'Giải trí',
      'cat_bills': 'Hóa đơn & Tiện ích',
      'cat_healthcare': 'Y tế',
      'cat_other_expense': 'Khác',

      // Ad-Free
      'watch_ad_remove_ads': 'Xem quảng cáo để tắt ads',
      'ad_free_active': 'Đang tắt ads',
      'remove_ads_title': 'Tắt quảng cáo',
      'watch_ad_prompt': 'Xem video quảng cáo để tắt toàn bộ ads trong',
      'ad_free_status': 'Còn lại',
      'watch_ad_button': 'Xem quảng cáo',
      'ad_free_granted': 'Tắt ads trong',
      'hours': 'giờ',
      'minutes': 'phút',
      'seconds': 'giây',

      // Mock & Reset Data
      'data_and_testing': 'Dữ liệu & Thử nghiệm',
      'generate_mock_data': 'Tạo dữ liệu mẫu',
      'generate_mock_data_desc':
          'Tạo hơn 100 giao dịch mẫu trong 6 tháng (Tháng 3 - 8)',
      'generate_mock_data_confirm':
          'Tạo bộ dữ liệu mẫu phong phú từ tháng 3 đến tháng 8/2026?',
      'mock_data_generated': 'Đã tạo thành công dữ liệu mẫu!',
      'reset_all_data': 'Xóa toàn bộ dữ liệu',
      'reset_all_data_desc': 'Xóa tất cả giao dịch, danh mục và khoản vay',
      'reset_all_data_confirm':
          'Hành động này sẽ xóa tất cả giao dịch, danh mục, và khoản vay. Không thể khôi phục.\n\nNhập "xoa" để xác nhận.',
      'reset_success': 'Đã xóa toàn bộ dữ liệu.',

      // Export & Backup
      'export_backup': 'Xuất & Sao lưu dữ liệu',
      'export_backup_desc': 'Xuất file Excel, CSV, PDF & Sao lưu JSON',
      'export_reports': 'Xuất báo cáo',
      'backup_restore': 'Sao lưu & Khôi phục',
      'export_excel': 'Excel (.xlsx)',
      'export_excel_desc': 'Đầy đủ sheet giao dịch, ngân sách và sổ nợ',
      'export_csv': 'CSV (.csv)',
      'export_csv_desc': 'Định dạng phổ biến chuẩn mã hóa UTF-8 BOM',
      'export_pdf': 'Báo cáo PDF (.pdf)',
      'export_pdf_desc': 'Bản báo cáo tài chính đẹp mắt sẵn sàng in ấn',
      'create_backup': 'Tạo bản sao lưu',
      'create_backup_desc': 'Lưu toàn bộ giao dịch, danh mục, ngân sách, sổ nợ',
      'restore_backup': 'Khôi phục dữ liệu',
      'restore_backup_desc': 'Chọn file sao lưu đã lưu trước đó để nạp lại',
      'restore_backup_hint': 'Chọn file sao lưu có định dạng .json đã lưu trước đó',
      'export_format': 'Định dạng xuất',
      'export_action': 'Xuất file',
      'export_time_range': 'Khoảng thời gian xuất',
      'export_success': 'Xuất file thành công!',
      'export_failed': 'Xuất file thất bại',
      'backup_created': 'Đã tạo bản sao lưu thành công!',
      'restore_success': 'Khôi phục dữ liệu thành công!',
      'restore_failed': 'Khôi phục dữ liệu thất bại',
      'import_preview_title': 'Xem trước bản sao lưu',
      'import_overwrite': 'Ghi đè toàn bộ',
      'import_merge': 'Gộp dữ liệu',
      'import_invalid_file': 'File sao lưu không hợp lệ',
      'total_categories_count': 'Danh mục',
      'total_transactions_count': 'Giao dịch',
      'total_budgets_count': 'Ngân sách tháng',
      'total_loans_count': 'Khoản vay & Nợ',
      'total_recurring_count': 'Giao dịch định kỳ',
      'exporting_data': 'Đang xuất dữ liệu...',
      'restoring_data': 'Đang khôi phục dữ liệu...',

      // Saving Goals
      'saving_goals': 'Mục tiêu tiết kiệm',
      'add_saving_goal': 'Tạo mục tiêu',
      'edit_saving_goal': 'Sửa mục tiêu',
      'delete_saving_goal': 'Xóa mục tiêu',
      'delete_saving_goal_confirm':
          'Bạn có chắc chắn muốn xóa mục tiêu này? Toàn bộ lịch sử nạp/rút sẽ bị xóa theo.',
      'goal_name': 'Tên mục tiêu',
      'target_amount': 'Số tiền mục tiêu',
      'target_date': 'Hạn chót',
      'optional_deadline': 'Hạn chót (tùy chọn)',
      'current_saved': 'Đã tích lũy',
      'remaining_to_save': 'Còn thiếu',
      'deposit': 'Nạp tiền',
      'withdraw': 'Rút tiền',
      'deposit_to_goal': 'Nạp tiền vào mục tiêu',
      'withdraw_from_goal': 'Rút tiền từ mục tiêu',
      'deposit_success': 'Nạp tiền thành công!',
      'withdraw_success': 'Rút tiền thành công!',
      'goal_created': 'Đã tạo mục tiêu thành công!',
      'goal_updated': 'Đã cập nhật mục tiêu!',
      'goal_deleted': 'Đã xóa mục tiêu!',
      'goal_completed': 'Đã hoàn thành',
      'goal_in_progress': 'Đang tích lũy',
      'all_goals': 'Tất cả mục tiêu',
      'total_target': 'Tổng mục tiêu',
      'total_saved': 'Tổng đã gom',
      'no_saving_goals': 'Chưa có mục tiêu tiết kiệm nào',
      'no_saving_goals_desc':
          'Tạo mục tiêu đầu tiên để tích lũy cho ước mơ của bạn',
      'history_logs': 'Lịch sử nạp / rút',
      'no_history_logs': 'Chưa có giao dịch nạp/rút nào',
    },
  };

  final String locale;

  AppLocalizations(this.locale);

  String translate(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  String get dashboard => translate('dashboard');
  String get transactions => translate('transactions');
  String get categories => translate('categories');
  String get recurring => translate('recurring');
  String get settings => translate('settings');

  String get income => translate('income');
  String get expense => translate('expense');
  String get monthlyBudget => translate('monthly_budget');
  String get budgetNotSet => translate('budget_not_set');
  String get copyPreviousMonthBudget => translate('copy_previous_month_budget');
  String get copyBudgetSuccess => translate('copy_budget_success');
  String get noBudgetThisMonth => translate('no_budget_this_month');
  String get setBudgetForMonth => translate('set_budget_for_month');
  String get selectMonthYear => translate('select_month_year');
  String get categoryBudgets => translate('category_budgets');
  String get totalMonthlyBudget => translate('total_monthly_budget');
  String get percentUsed => translate('percent_used');
  String get totalTransactions => translate('total_transactions');
  String get currentMonth => translate('current_month');
  String get balance => translate('balance');
  String get recentTransactions => translate('recent_transactions');
  String get viewAll => translate('view_all');
  String get incomeByCategory => translate('income_by_category');
  String get expenseByCategory => translate('expense_by_category');
  String get noData => translate('no_data');
  String get incomeVsExpense => translate('income_vs_expense');
  String get spendingTrend => translate('spending_trend');
  String get selectMonth => translate('select_month');
  String get selectYear => translate('select_year');

  String get noTransactions => translate('no_transactions');
  String get addTransaction => translate('add_transaction');
  String get addMore => translate('add_more');
  String get saveAll => translate('save_all');
  String get type => translate('type');
  String get amount => translate('amount');
  String get formula => translate('formula');
  String get category => translate('category');
  String get note => translate('note');
  String get noCategory => translate('no_category');
  String get deleteTransaction => translate('delete_transaction');
  String get deleteTransactionConfirm =>
      translate('delete_transaction_confirm');
  String get transactionDeleted => translate('transaction_deleted');
  String get transactionCreated => translate('transaction_created');
  String get fillAllFields => translate('fill_all_fields');

  String get noCategories => translate('no_categories');
  String get noCategoriesWarning => translate('no_categories_warning');
  String get addCategory => translate('add_category');
  String get editCategory => translate('edit_category');
  String get deleteCategory => translate('delete_category');
  String get categoryName => translate('category_name');
  String get deleteCategoryConfirm => translate('delete_category_confirm');
  String get categoryAdded => translate('category_added');
  String get categoryUpdated => translate('category_updated');
  String get categoryDeleted => translate('category_deleted');

  String get recurringTransactions => translate('recurring_transactions');
  String get noRecurring => translate('no_recurring');
  String get addRecurring => translate('add_recurring');
  String get editRecurring => translate('edit_recurring');
  String get deleteRecurring => translate('delete_recurring');
  String get deleteRecurringConfirm => translate('delete_recurring_confirm');
  String get recurringDeleted => translate('recurring_deleted');
  String get recurringCreated => translate('recurring_created');
  String get recurringUpdated => translate('recurring_updated');
  String get runNow => translate('run_now');
  String get runNowConfirm => translate('run_now_confirm');
  String get transactionTriggered => translate('transaction_triggered');
  String get name => translate('name');
  String get frequency => translate('frequency');
  String get interval => translate('interval');
  String get dayOfWeek => translate('day_of_week');
  String get dayOfMonth => translate('day_of_month');
  String get nextRun => translate('next_run');
  String get daily => translate('daily');
  String get weekly => translate('weekly');
  String get monthly => translate('monthly');
  String get byDay => translate('by_day');
  String get byWeek => translate('by_week');
  String get byMonth => translate('by_month');
  String get days => translate('days');
  String get week => translate('week');
  String get weeks => translate('weeks');
  String get month => translate('month');
  String get months => translate('months');
  String get every => translate('every');
  String get on => translate('on');
  String get day => translate('day');
  String get sunday => translate('sunday');
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');

  String get monthlyBudgetSetting => translate('monthly_budget_setting');
  String get currency => translate('currency');
  String get language => translate('language');
  String get save => translate('save');
  String get settingsSaved => translate('settings_saved');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get chinese => translate('chinese');
  String get about => translate('about');
  String get appDescription => translate('app_description');

  String get account => translate('account');
  String get syncData => translate('sync_data');
  String get syncing => translate('syncing');
  String get syncSuccess => translate('sync_success');
  String get syncFailed => translate('sync_failed');
  String get logout => translate('logout');
  String get logoutConfirm => translate('logout_confirm');
  String get syncingData => translate('syncing_data');
  String get logoutError => translate('logout_error');
  String get loadingData => translate('loading_data');
  String get internetRequiredForLogin => translate('internet_required_for_login');

  String get email => translate('email');
  String get password => translate('password');
  String get login => translate('login');
  String get register => translate('register');
  String get dontHaveAccount => translate('dont_have_account');
  String get createNewAccount => translate('create_new_account');
  String get registerToSync => translate('register_to_sync');
  String get confirmPassword => translate('confirm_password');
  String get appTagline => translate('app_tagline');
  String get forgotPassword => translate('forgot_password');
  String get resetPassword => translate('reset_password');
  String get resetPasswordInstruction => translate('reset_password_instruction');
  String get sendResetLink => translate('send_reset_link');
  String get resetLinkSent => translate('reset_link_sent');
  String get changePassword => translate('change_password');
  String get currentPassword => translate('current_password');
  String get newPassword => translate('new_password');
  String get confirmNewPassword => translate('confirm_new_password');
  String get passwordChanged => translate('password_changed');
  String get changePasswordFailed => translate('change_password_failed');
  String get pleaseEnterCurrentPassword => translate('please_enter_current_password');
  String get pleaseEnterNewPassword => translate('please_enter_new_password');
  String get newPasswordsNotMatch => translate('new_passwords_not_match');
  String get newPasswordMustBeDifferent => translate('new_password_must_be_different');

  String get pleaseEnterEmail => translate('please_enter_email');
  String get invalidEmail => translate('invalid_email');
  String get pleaseEnterPassword => translate('please_enter_password');
  String get passwordMin6 => translate('password_min_6');
  String get passwordMin8 => translate('password_min_8');
  String get passwordHelper => translate('password_helper');
  String get passwordNeedUppercase => translate('password_need_uppercase');
  String get passwordNeedLowercase => translate('password_need_lowercase');
  String get passwordNeedNumber => translate('password_need_number');
  String get passwordNeedSpecial => translate('password_need_special');
  String get pleaseConfirmPassword => translate('please_confirm_password');
  String get passwordsNotMatch => translate('passwords_not_match');

  String get loginFailed => translate('login_failed');
  String get invalidCredentials => translate('invalid_credentials');
  String get emailNotConfirmed => translate('email_not_confirmed');
  String get networkError => translate('network_error');
  String get registerFailed => translate('register_failed');
  String get emailAlreadyRegistered => translate('email_already_registered');
  String get passwordTooWeak => translate('password_too_weak');
  String get systemError => translate('system_error');
  String get registerSuccessConfirm => translate('register_success_confirm');
  String get registerSuccess => translate('register_success');

  String get cancel => translate('cancel');
  String get add => translate('add');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get error => translate('error');
  String get categoryOptional => translate('category_optional');
  String get done => translate('done');

  String get pleaseEnterAmount => translate('please_enter_amount');
  String get amountCannotNegative => translate('amount_cannot_negative');
  String get invalidFormula => translate('invalid_formula');
  String get currencyConverter => translate('currency_converter');
  String get currencyConverterHint => translate('currency_converter_hint');
  String get selectCurrency => translate('select_currency');
  String get pleaseEnterAmountFirst => translate('please_enter_amount_first');
  String get invalidAmount => translate('invalid_amount');
  String get cannotLoadSettings => translate('cannot_load_settings');
  String get failedToFetchRate => translate('failed_to_fetch_rate');

  String get item => translate('item');
  String get transaction => translate('transaction');
  String get optional => translate('optional');
  String get incomePlus => translate('income_plus');
  String get expenseMinus => translate('expense_minus');
  String get longPressHint => translate('long_press_hint');

  String get threeMonths => translate('3_months');
  String get sixMonths => translate('6_months');
  String get oneYear => translate('1_year');

  String get filter => translate('filter');
  String get filterTransactions => translate('filter_transactions');
  String get time => translate('time');
  String get all => translate('all');
  String get thisMonth => translate('this_month');
  String get lastMonth => translate('last_month');
  String get last3Months => translate('last_3_months');
  String get customRange => translate('custom_range');
  String get allTypes => translate('all_types');
  String get allCategories => translate('all_categories');
  String get amountRange => translate('amount_range');
  String get minAmount => translate('min_amount');
  String get maxAmount => translate('max_amount');
  String get clearAll => translate('clear_all');
  String get apply => translate('apply');
  String get fromDate => translate('from_date');
  String get toDate => translate('to_date');
  String get activeFilters => translate('active_filters');
  String get loadMore => translate('load_more');
  String get selectMultiple => translate('select_multiple');
  String get transactionDateLabel => translate('transaction_date');
  String get createdAtLabel => translate('created_at');
  String get updatedAtLabel => translate('updated_at');
  String get txDateShort => translate('tx_date_short');
  String get createdAtShort => translate('created_at_short');
  String get updatedAtShort => translate('updated_at_short');
  String get originalDate => translate('original_date');

  // Ad-Free
  String get watchAdRemoveAds => translate('watch_ad_remove_ads');
  String get adFreeActive => translate('ad_free_active');
  String get removeAdsTitle => translate('remove_ads_title');
  String get watchAdPrompt => translate('watch_ad_prompt');
  String get adFreeStatus => translate('ad_free_status');
  String get watchAdButton => translate('watch_ad_button');
  String get adFreeGranted => translate('ad_free_granted');
  String get hours => translate('hours');
  String get minutes => translate('minutes');
  String get seconds => translate('seconds');

  // Mock & Reset Data
  String get dataAndTesting => translate('data_and_testing');
  String get generateMockData => translate('generate_mock_data');
  String get generateMockDataDesc => translate('generate_mock_data_desc');
  String get generateMockDataConfirm =>
      translate('generate_mock_data_confirm');
  String get mockDataGenerated => translate('mock_data_generated');
  String get resetAllData => translate('reset_all_data');
  String get resetAllDataDesc => translate('reset_all_data_desc');
  String get resetAllDataConfirm => translate('reset_all_data_confirm');
  String get resetSuccess => translate('reset_success');

  // Export & Backup Getters
  String get exportBackup => translate('export_backup');
  String get exportBackupDesc => translate('export_backup_desc');
  String get exportReports => translate('export_reports');
  String get backupRestore => translate('backup_restore');
  String get exportExcel => translate('export_excel');
  String get exportExcelDesc => translate('export_excel_desc');
  String get exportCsv => translate('export_csv');
  String get exportCsvDesc => translate('export_csv_desc');
  String get exportPdf => translate('export_pdf');
  String get exportPdfDesc => translate('export_pdf_desc');
  String get createBackup => translate('create_backup');
  String get createBackupDesc => translate('create_backup_desc');
  String get restoreBackup => translate('restore_backup');
  String get restoreBackupDesc => translate('restore_backup_desc');
  String get exportTimeRange => translate('export_time_range');
  String get exportSuccess => translate('export_success');
  String get exportFailed => translate('export_failed');
  String get backupCreated => translate('backup_created');
  String get restoreSuccess => translate('restore_success');
  String get restoreFailed => translate('restore_failed');
  String get importPreviewTitle => translate('import_preview_title');
  String get importOverwrite => translate('import_overwrite');
  String get importMerge => translate('import_merge');
  String get importInvalidFile => translate('import_invalid_file');
  String get totalCategoriesCount => translate('total_categories_count');
  String get totalTransactionsCount => translate('total_transactions_count');
  String get totalBudgetsCount => translate('total_budgets_count');
  String get totalLoansCount => translate('total_loans_count');
  String get totalRecurringCount => translate('total_recurring_count');
  String get exportingData => translate('exporting_data');
  String get restoringData => translate('restoring_data');
  String get restoreBackupHint => translate('restore_backup_hint');
  String get exportFormat => translate('export_format');
  String get exportAction => translate('export_action');

  // Saving Goals Getters
  String get savingGoals => translate('saving_goals');
  String get addSavingGoal => translate('add_saving_goal');
  String get editSavingGoal => translate('edit_saving_goal');
  String get deleteSavingGoal => translate('delete_saving_goal');
  String get deleteSavingGoalConfirm =>
      translate('delete_saving_goal_confirm');
  String get goalName => translate('goal_name');
  String get targetAmount => translate('target_amount');
  String get targetDate => translate('target_date');
  String get optionalDeadline => translate('optional_deadline');
  String get currentSaved => translate('current_saved');
  String get remainingToSave => translate('remaining_to_save');
  String get deposit => translate('deposit');
  String get withdraw => translate('withdraw');
  String get depositToGoal => translate('deposit_to_goal');
  String get withdrawFromGoal => translate('withdraw_from_goal');
  String get depositSuccess => translate('deposit_success');
  String get withdrawSuccess => translate('withdraw_success');
  String get goalCreated => translate('goal_created');
  String get goalUpdated => translate('goal_updated');
  String get goalDeleted => translate('goal_deleted');
  String get goalCompleted => translate('goal_completed');
  String get goalInProgress => translate('goal_in_progress');
  String get allGoals => translate('all_goals');
  String get totalTarget => translate('total_target');
  String get totalSaved => translate('total_saved');
  String get noSavingGoals => translate('no_saving_goals');
  String get noSavingGoalsDesc => translate('no_saving_goals_desc');
  String get historyLogs => translate('history_logs');
  String get noHistoryLogs => translate('no_history_logs');

  // Translate default category name by ID
  String translateCategoryName(String categoryId, String defaultName) {
    if (categoryId.startsWith('cat_')) {
      return translate(categoryId);
    }
    return defaultName;
  }

  // Get month name by number (1-12)
  String getMonthName(int month) {
    final monthKeys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    if (month >= 1 && month <= 12) {
      return translate(monthKeys[month - 1]);
    }
    return month.toString();
  }
}
