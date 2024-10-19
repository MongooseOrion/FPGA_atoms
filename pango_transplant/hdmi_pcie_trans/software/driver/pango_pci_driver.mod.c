#include <linux/module.h>
#define INCLUDE_VERMAGIC
#include <linux/build-salt.h>
#include <linux/elfnote-lto.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

BUILD_SALT;
BUILD_LTO_INFO;

MODULE_INFO(vermagic, VERMAGIC_STRING);
MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

#ifdef CONFIG_RETPOLINE
MODULE_INFO(retpoline, "Y");
#endif

static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0x2b4dfa79, "module_layout" },
	{ 0xdd7d16aa, "class_destroy" },
	{ 0x41273767, "device_destroy" },
	{ 0x1b2f621, "device_create" },
	{ 0x1683011b, "__class_create" },
	{ 0x5dfff31a, "pci_unregister_driver" },
	{ 0xf63e7ece, "__pci_register_driver" },
	{ 0x6091b333, "unregister_chrdev_region" },
	{ 0x8bcfa640, "cdev_del" },
	{ 0x5bf0ad7d, "cdev_add" },
	{ 0x7e0c3c2, "cdev_init" },
	{ 0xe3ec2f2b, "alloc_chrdev_region" },
	{ 0xcbd4898c, "fortify_panic" },
	{ 0x65cd4d1a, "pci_write_config_dword" },
	{ 0xcb5aa9bc, "dma_alloc_attrs" },
	{ 0x69acdf38, "memcpy" },
	{ 0x13c49cc2, "_copy_from_user" },
	{ 0x4a453f53, "iowrite32" },
	{ 0xfb578fc5, "memset" },
	{ 0x9b7fdc48, "dma_free_attrs" },
	{ 0x449ad0a7, "memcmp" },
	{ 0xcf2a6966, "up" },
	{ 0xeca4aee1, "pv_ops" },
	{ 0xba8fbd64, "_raw_spin_lock" },
	{ 0x6bd0e573, "down_interruptible" },
	{ 0x1b5dc0d5, "pci_release_region" },
	{ 0xedc03953, "iounmap" },
	{ 0x37a0cba, "kfree" },
	{ 0xd0da656b, "__stack_chk_fail" },
	{ 0x419b4012, "pci_disable_device" },
	{ 0x5f664094, "pci_write_config_word" },
	{ 0xeb233a45, "__kmalloc" },
	{ 0xde80cd09, "ioremap" },
	{ 0xd5e321d4, "pci_clear_master" },
	{ 0xbcd1489e, "pci_request_region" },
	{ 0x3eeb62ee, "pci_set_master" },
	{ 0xe69728ac, "pci_find_capability" },
	{ 0xcc364e2d, "pci_read_config_byte" },
	{ 0x23f3d4d7, "pci_read_config_word" },
	{ 0x87a21cb3, "__ubsan_handle_out_of_bounds" },
	{ 0xead99a33, "pci_read_config_dword" },
	{ 0x25e13516, "dma_set_coherent_mask" },
	{ 0x53b6898, "dma_set_mask" },
	{ 0xdb8cbd7c, "pci_enable_device" },
	{ 0x92997ed8, "_printk" },
	{ 0x6b10bee1, "_copy_to_user" },
	{ 0x5b8239ca, "__x86_return_thunk" },
	{ 0xbdfb6dbb, "__fentry__" },
};

MODULE_INFO(depends, "");


MODULE_INFO(srcversion, "4BFF5291F01147F84743D04");
