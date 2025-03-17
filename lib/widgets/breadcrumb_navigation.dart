import 'package:flutter/material.dart';

/// Model for a breadcrumb navigation item
class BreadcrumbItem {
  /// Display label for the breadcrumb
  final String label;
  
  /// Route to navigate to when tapped
  final String route;
  
  /// Fallback icon to display if no icon asset is provided
  final IconData fallbackIcon;
  
  /// Optional asset path for icon image
  final String? iconAsset;
  
  /// Optional arguments to pass when navigating
  final Map<String, dynamic>? arguments;

  /// Creates a breadcrumb item
  BreadcrumbItem({
    required this.label,
    required this.route,
    required this.fallbackIcon,
    this.iconAsset,
    this.arguments,
  });
}

/// A widget that displays breadcrumb navigation for app context
class BreadcrumbNavigation extends StatelessWidget {
  /// List of breadcrumb items to display
  final List<BreadcrumbItem> items;
  
  /// Callback for when a breadcrumb is tapped for navigation
  final Function(String route, Map<String, dynamic>? arguments)? onNavigate;
  
  /// Style for the breadcrumb container
  final BoxDecoration? decoration;
  
  /// Padding for the breadcrumb container
  final EdgeInsetsGeometry padding;
  
  /// Background color for the breadcrumb container
  final Color? backgroundColor;
  
  /// Style for the selected breadcrumb item
  final TextStyle? selectedStyle;
  
  /// Style for unselected breadcrumb items
  final TextStyle? unselectedStyle;
  
  /// Separator widget between breadcrumbs
  final Widget? separator;

  /// Creates a breadcrumb navigation widget
  const BreadcrumbNavigation({
    Key? key,
    required this.items,
    this.onNavigate,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.backgroundColor,
    this.selectedStyle,
    this.unselectedStyle,
    this.separator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use provided styles or default ones
    final TextStyle activeStyle = selectedStyle ?? 
        TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          fontSize: 14,
        );
        
    final TextStyle inactiveStyle = unselectedStyle ?? 
        TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        );
    
    // Use provided separator or default chevron icon
    final Widget separatorWidget = separator ?? 
        Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]);
    
    return Container(
      padding: padding,
      decoration: decoration ?? 
        BoxDecoration(
          color: backgroundColor ?? Colors.grey[50],
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(items.length * 2 - 1, (index) {
            // Even indices are breadcrumb items, odd indices are separators
            if (index.isOdd) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: separatorWidget,
              );
            } else {
              final itemIndex = index ~/ 2;
              final item = items[itemIndex];
              final isLast = itemIndex == items.length - 1;
              
              return _buildBreadcrumbItem(
                context, 
                item, 
                isLast ? activeStyle : inactiveStyle,
              );
            }
          }),
        ),
      ),
    );
  }
  
  /// Builds an individual breadcrumb item
  Widget _buildBreadcrumbItem(
    BuildContext context, 
    BreadcrumbItem item,
    TextStyle style,
  ) {
    return InkWell(
      onTap: () {
        if (onNavigate != null) {
          onNavigate!(item.route, item.arguments);
        } else {
          // Default navigation behavior if no callback provided
          Navigator.pushNamed(
            context, 
            item.route,
            arguments: item.arguments,
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display icon (asset image or fallback icon)
            if (item.iconAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Image.asset(
                  item.iconAsset!,
                  width: 16,
                  height: 16,
                  errorBuilder: (_, __, ___) => Icon(
                    item.fallbackIcon,
                    size: 16,
                    color: style.color,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  item.fallbackIcon,
                  size: 16,
                  color: style.color,
                ),
              ),
              
            // Display breadcrumb label
            Text(
              item.label,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// An animated version of breadcrumb navigation that fades in items
class AnimatedBreadcrumbNavigation extends StatefulWidget {
  /// List of breadcrumb items to display
  final List<BreadcrumbItem> items;
  
  /// Callback for when a breadcrumb is tapped for navigation
  final Function(String route, Map<String, dynamic>? arguments)? onNavigate;
  
  /// Style for the breadcrumb container
  final BoxDecoration? decoration;
  
  /// Padding for the breadcrumb container
  final EdgeInsetsGeometry padding;
  
  /// Background color for the breadcrumb container
  final Color? backgroundColor;
  
  /// Style for the selected breadcrumb item
  final TextStyle? selectedStyle;
  
  /// Style for unselected breadcrumb items
  final TextStyle? unselectedStyle;
  
  /// Separator widget between breadcrumbs
  final Widget? separator;
  
  /// Animation duration
  final Duration animationDuration;

  /// Creates an animated breadcrumb navigation widget
  const AnimatedBreadcrumbNavigation({
    Key? key,
    required this.items,
    this.onNavigate,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.backgroundColor,
    this.selectedStyle,
    this.unselectedStyle,
    this.separator,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  _AnimatedBreadcrumbNavigationState createState() => _AnimatedBreadcrumbNavigationState();
}

class _AnimatedBreadcrumbNavigationState extends State<AnimatedBreadcrumbNavigation> {
  List<BreadcrumbItem> _visibleItems = [];
  
  @override
  void initState() {
    super.initState();
    _animateItems();
  }
  
  @override
  void didUpdateWidget(AnimatedBreadcrumbNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the items list has changed, animate the new items
    if (widget.items != oldWidget.items) {
      _visibleItems = [];
      _animateItems();
    }
  }
  
  /// Animate breadcrumb items appearing one by one
  void _animateItems() async {
    if (widget.items.isEmpty) return;
    
    for (int i = 0; i < widget.items.length; i++) {
      await Future.delayed(widget.animationDuration ~/ widget.items.length);
      
      if (mounted) {
        setState(() {
          _visibleItems = widget.items.sublist(0, i + 1);
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BreadcrumbNavigation(
      items: _visibleItems,
      onNavigate: widget.onNavigate,
      decoration: widget.decoration,
      padding: widget.padding,
      backgroundColor: widget.backgroundColor,
      selectedStyle: widget.selectedStyle,
      unselectedStyle: widget.unselectedStyle,
      separator: widget.separator,
    );
  }
}

/// A horizontal breadcrumb trail with hover effects
class HoverBreadcrumbNavigation extends StatefulWidget {
  /// List of breadcrumb items to display
  final List<BreadcrumbItem> items;
  
  /// Callback for when a breadcrumb is tapped for navigation
  final Function(String route, Map<String, dynamic>? arguments)? onNavigate;
  
  /// Style for the breadcrumb container
  final BoxDecoration? decoration;
  
  /// Padding for the breadcrumb container
  final EdgeInsetsGeometry padding;
  
  /// Background color for the breadcrumb container
  final Color? backgroundColor;
  
  /// Style for the selected breadcrumb item
  final TextStyle? selectedStyle;
  
  /// Style for unselected breadcrumb items
  final TextStyle? unselectedStyle;
  
  /// Hover style for breadcrumb items
  final TextStyle? hoverStyle;
  
  /// Separator widget between breadcrumbs
  final Widget? separator;
  
  /// Creates a hover-enabled breadcrumb navigation widget
  const HoverBreadcrumbNavigation({
    Key? key,
    required this.items,
    this.onNavigate,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.backgroundColor,
    this.selectedStyle,
    this.unselectedStyle,
    this.hoverStyle,
    this.separator,
  }) : super(key: key);

  @override
  _HoverBreadcrumbNavigationState createState() => _HoverBreadcrumbNavigationState();
}

class _HoverBreadcrumbNavigationState extends State<HoverBreadcrumbNavigation> {
  int? _hoveredIndex;
  
  @override
  Widget build(BuildContext context) {
    // Use provided styles or default ones
    final TextStyle activeStyle = widget.selectedStyle ??
        TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          fontSize: 14,
        );
        
    final TextStyle inactiveStyle = widget.unselectedStyle ??
        TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        );
        
    final TextStyle hoverStyle = widget.hoverStyle ??
        TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).primaryColor.withOpacity(0.8),
          fontSize: 14,
        );
    
    // Use provided separator or default chevron icon
    final Widget separatorWidget = widget.separator ??
        Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]);
    
    return Container(
      padding: widget.padding,
      decoration: widget.decoration ??
        BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey[50],
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.items.length * 2 - 1, (index) {
            // Even indices are breadcrumb items, odd indices are separators
            if (index.isOdd) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: separatorWidget,
              );
            } else {
              final itemIndex = index ~/ 2;
              final item = widget.items[itemIndex];
              final isLast = itemIndex == widget.items.length - 1;
              
              // Determine which style to use based on state
              TextStyle style;
              if (isLast) {
                style = activeStyle;
              } else if (_hoveredIndex == itemIndex) {
                style = hoverStyle;
              } else {
                style = inactiveStyle;
              }
              
              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = itemIndex),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: _buildBreadcrumbItem(context, item, style, itemIndex),
              );
            }
          }),
        ),
      ),
    );
  }
  
  /// Builds an individual breadcrumb item with hover effect
  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item,
    TextStyle style,
    int index,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _hoveredIndex == index ? Colors.grey[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onNavigate != null) {
            widget.onNavigate!(item.route, item.arguments);
          } else {
            // Default navigation behavior if no callback provided
            Navigator.pushNamed(
              context,
              item.route,
              arguments: item.arguments,
            );
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display icon (asset image or fallback icon)
              if (item.iconAsset != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Image.asset(
                    item.iconAsset!,
                    width: 16,
                    height: 16,
                    errorBuilder: (_, __, ___) => Icon(
                      item.fallbackIcon,
                      size: 16,
                      color: style.color,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    item.fallbackIcon,
                    size: 16,
                    color: style.color,
                  ),
                ),
                
              // Display breadcrumb label
              Text(
                item.label,
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}