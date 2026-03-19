import '../models/brief_content.dart';

class CozyGamesCuratedCards {
  CozyGamesCuratedCards._();

  static const List<BriefContentItem> cards = <BriefContentItem>[
    BriefContentItem(
      id: 'cozy_stardew_valley',
      title: 'Stardew Valley',
      subtitle: 'Farm, fish, and make tiny, satisfying progress at your pace.',
      source: 'Curated by NANA',
      badge: 'Cozy classic',
      metadata: <String, String>{
        'Platform': 'Switch • PC • Mobile',
        'Why it fits': 'Gentle loops and low-pressure goals.',
      },
    ),
    BriefContentItem(
      id: 'cozy_unpacking',
      title: 'Unpacking',
      subtitle: 'A calm organizing game with short chapters and soft storytelling.',
      source: 'Curated by NANA',
      badge: '10-minute unwind',
      metadata: <String, String>{
        'Platform': 'Switch • PC • PlayStation • Xbox',
        'Why it fits': 'Quiet, tactile, and easy to dip into.',
      },
    ),
    BriefContentItem(
      id: 'cozy_a_short_hike',
      title: 'A Short Hike',
      subtitle: 'Explore a little island, wander freely, and stop whenever you want.',
      source: 'Curated by NANA',
      badge: 'Feel-good',
      metadata: <String, String>{
        'Platform': 'Switch • PC',
        'Why it fits': 'Warm tone with no heavy time pressure.',
      },
    ),
  ];
}
