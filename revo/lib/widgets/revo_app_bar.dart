import 'package:flutter/material.dart';

class RevoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onCartTap;
  final int cartCount;
  final bool showMenu;
  final bool showCart;
  final bool showBack;
  final List<Widget>? actions;

  const RevoAppBar({
    super.key,
    this.onMenuTap,
    this.onCartTap,
    this.cartCount = 0,
    this.showMenu = true,
    this.showCart = true,
    this.showBack = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, size: 24),
              onPressed: () => Navigator.pop(context),
            )
          : showMenu
              ? IconButton(
                  icon: const Icon(Icons.menu, size: 24),
                  onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                )
              : null,
      title: const Text(
        'REVO',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
      centerTitle: true,
      actions: [
        if (actions != null) ...actions!,
        if (showCart)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                onPressed: onCartTap,
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }
}
