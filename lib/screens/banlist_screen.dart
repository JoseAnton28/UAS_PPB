return ListView.builder(
  itemCount: cards.length,
  itemBuilder: (_, i) {
    final c = cards[i];
    final displayType = c.type.contains('Tuner') || c.type.contains('Gemini')
        ? 'Effect Monster'
        : c.type;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardDetailScreen(card: c)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: c.smallImageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      displayType.split(' ').first,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade300),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70)
            ],
          ),
        ),
      ),
    );
  },
);
