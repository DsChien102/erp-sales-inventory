-- Install messaging tables + RPCs for all bounded contexts (whitelist enforced in install fn).

select platform.install_module_messaging('iam');
select platform.install_module_messaging('catalog');
select platform.install_module_messaging('sales');
select platform.install_module_messaging('inventory');
select platform.install_module_messaging('costing');
select platform.install_module_messaging('accounting');
select platform.install_module_messaging('dashboard');
