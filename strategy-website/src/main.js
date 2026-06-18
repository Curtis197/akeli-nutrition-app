import './style.css'

// 1. Data Definitions

const CONCEPTS = [
  // Concepts Internes
  {
    id: 'realignment',
    name: 'Le Réalignment Nutritionnel',
    type: 'internal',
    definition: 'Démarche d\'ajustement progressif de l\'alimentation d\'origine à la sédentarité urbaine, refusant le concept punitif du "régime".',
    context: 'Akeli postule que la cuisine traditionnelle est saine et structurante. La solution est de recalibrer sa charge métabolique, non de la diaboliser.',
    ref: 'AKELI_PHILOSOPHIE_REALIGNMENT.md'
  },
  {
    id: 'desynchronization',
    name: 'La Désynchronisation',
    type: 'internal',
    definition: 'Décalage biologique causé par l\'apport calorique traditionnel (conçu pour des corps très actifs) chez un individu moderne sédentaire.',
    context: 'Ce n\'est pas la cuisine traditionnelle qui pose problème, mais son décalage physiologique avec un mode de vie de bureau assis en climat tempéré.',
    ref: 'AKELI_PHILOSOPHIE_REALIGNMENT.md'
  },
  {
    id: 'modernity',
    name: 'Modernité contre Modernité',
    type: 'internal',
    definition: 'Utiliser la data science, la vectorisation et les plateformes numériques pour réparer les fractures physiques et culturelles créées par la modernité.',
    context: 'Soigner l\'isolement et la malbouffe industrielle avec les mêmes canaux technologiques qui les ont favorisés.',
    ref: 'AKELI_VISION_UNIVERSELLE.md'
  },
  {
    id: 'permanence',
    name: 'La Permanence comme Fondation',
    type: 'internal',
    definition: 'Aligner le projet sur ce qui dure (les cultures et habitudes séculaires du peuple) plutôt que sur les innovations marketing éphémères.',
    context: 'Akeli n\'innove pas dans le vide ; il révèle un besoin constant et pérenne de se nourrir culturellement.',
    ref: 'AKELI_SESSION_FONDATION_MARS2026.md'
  },
  {
    id: 'bic-gillette',
    name: 'Le Positionnement Bic/Gillette',
    type: 'internal',
    definition: 'Positionnement basé sur la fiabilité, la discrétion et l\'utilité répétée au quotidien pour toutes les classes sociales.',
    context: 'Akeli ne se vend pas comme une promesse spectaculaire d\'aspiration, mais comme un outil quotidien et fiable, présent à chaque repas.',
    ref: 'AKELI_SESSION_FONDATION_MARS2026.md'
  },
  {
    id: 'sociology',
    name: 'La Tripartition Sociologique',
    type: 'internal',
    definition: 'Segmentation opérationnelle de la diaspora en trois profils (Primo-arrivant, Déraciné, Identitaire) pour guider le produit.',
    context: 'Permet d\'éviter le prosélytisme culturel et d\'intégrer toutes les réalités vécues sans condescendance startup.',
    ref: 'AKELI_REALITE_SOCIOLOGIQUE.md'
  },
  {
    id: 'translator',
    name: 'Le Créateur Traducteur',
    type: 'internal',
    definition: 'Posture du créateur de contenu comme passeur de savoir culinaire, qui adapte le patrimoine à des contraintes de vie contemporaines.',
    context: 'Il ne cherche pas à être un influenceur esthétique, mais résout un problème métabolique réel pour sa communauté.',
    ref: 'AKELI_COMMUNICATION_CREATEUR.md'
  },
  {
    id: 'entretien-lang',
    name: 'Le Langage d\'Entretien',
    type: 'internal',
    definition: 'Registre d\'écriture interne d\'Akeli. Dense, structurel et philosophique, il constitue la couche invisible du projet.',
    context: 'Définit les règles d\'architecture de valeur et de produit sans jamais transparaître directement dans le ton public.',
    ref: 'AKELI_SESSION_FONDATION_MARS2026.md'
  },
  {
    id: 'emotion-collective',
    name: 'L\'Émotion Collective',
    type: 'internal',
    definition: 'Axe de communication unifiant la communauté sur des réalités vécues communes, s\'opposant à la fragmentation algorithmique moderne.',
    context: 'Le lien communautaire se forge sur un socle de vérités partagées simultanément (proverbes, récits quotidiens).',
    ref: 'AKELI_SESSION_FONDATION_MARS2026.md'
  },

  // Concepts Publics
  {
    id: 'dietary-audience',
    name: 'L\'Audience Diététique',
    type: 'public',
    definition: 'Abonnés actifs qui consomment et valident les recettes d\'un créateur au quotidien pour nourrir leur propre corps.',
    context: 'L\'utilisateur ne fait pas que regarder du divertissement alimentaire (likes/vues) ; il confie son bien-être au créateur.',
    ref: 'AKELI_COMMUNICATION_CREATEUR.md'
  },
  {
    id: 'fan-mode',
    name: 'Le Mode Fan',
    type: 'public',
    definition: 'Abonnement direct allouant 1€ garanti/mois à un créateur en échange d\'une alimentation composée à 90% de son catalogue.',
    context: 'Techniquement protégé par un verrou bloquant l\'accès à plus de 9 recettes tierces par mois calendaire.',
    ref: 'AKELI_MODE_FAN.md'
  },
  {
    id: 'living-system',
    name: 'La Cuisine Système Vivant',
    type: 'public',
    definition: 'Concept valorisant la tradition culinaire comme un processus d\'adaptation continu, absorbant les ingrédients locaux.',
    context: 'Explique aux utilisateurs que modifier une recette avec des légumes européens de saison s\'inscrit dans la tradition historique.',
    ref: 'AKELI_CUISINE_SYSTEME_VIVANT.md'
  },
  {
    id: 'structural-recipe',
    name: 'La Recette Structurelle',
    type: 'public',
    definition: 'Décomposition logique d\'une recette (ex: base + liant + texture) pour permettre des substitutions de macros en temps réel.',
    context: 'Règle éditoriale : "La tradition donne le cadre, votre créativité remplit le cadre."',
    ref: 'AKELI_CUISINE_SYSTEME_VIVANT.md'
  },
  {
    id: 'transparency',
    name: 'La Preuve par les Résultats',
    type: 'public',
    definition: 'Publication transparente du taux de réussite d\'un créateur après 6 mois d\'accumulation de données d\'observance.',
    context: 'Protège les nouveaux créateurs et valorise la qualité diététique réelle contre le packaging esthétique des réseaux.',
    ref: 'AKELI_COMMUNICATION_CREATEUR.md'
  },
  {
    id: 'public-lang',
    name: 'Le Langage Public',
    type: 'public',
    definition: 'Voix publique d\'Akeli : simple, directe, imagée et ancrée dans le réel, bannissant tout jargon technique ou condescendance.',
    context: 'S\'adresse directement au vécu collectif partagé pour susciter l\'identification immédiate.',
    ref: 'AKELI_SESSION_FONDATION_MARS2026.md'
  }
]

const DOCUMENTS = [
  // Category: vision (Vision & Philosophie)
  {
    fileName: 'AKELI_PHILOSOPHIE_REALIGNMENT.md',
    title: 'Philosophie du Réalignment',
    desc: 'Définition du concept de réalignment nutritionnel contre la notion punitive de régime, et analyse de la désynchronisation métabolique.',
    category: 'vision'
  },
  {
    fileName: 'AKELI_VISION_UNIVERSELLE.md',
    title: 'Vision Universelle d\'Akeli',
    desc: 'Pourquoi Akeli a vocation à s\'adresser à toutes les communautés sédentarisées subissant la malbouffe industrielle.',
    category: 'vision'
  },
  {
    fileName: 'AKELI_SESSION_FONDATION_MARS2026.md',
    title: 'Session de Fondation (Mars 2026)',
    desc: 'Orientations stratégiques initiales, choix techniques fondamentaux et principes du positionnement Bic/Gillette.',
    category: 'vision'
  },
  {
    fileName: 'AKELI_REALITE_SOCIOLOGIQUE.md',
    title: 'Réalité Sociologique & Personas',
    desc: 'Modélisation de la diaspora en trois profils d\'utilisateurs (Primo-arrivant, Déraciné, Identitaire) pour guider le produit.',
    category: 'vision'
  },
  {
    fileName: 'AKELI_CUISINE_SYSTEME_VIVANT.md',
    title: 'La Cuisine comme Système Vivant',
    desc: 'Comment concilier la tradition culinaire avec l\'adaptation constante aux ingrédients locaux et de saison.',
    category: 'vision'
  },
  {
    fileName: 'AKELI_CUISINE_ADAPTATION.md',
    title: 'Guide d\'Adaptation Culinaire',
    desc: 'Méthodes concrètes de substitution d\'ingrédients pour équilibrer la charge glycémique des repas traditionnels.',
    category: 'vision'
  },
  {
    fileName: 'AKELI_CONCEPT_INDEX.md',
    title: 'Index Complet des Concepts',
    desc: 'Le registre de tous les concepts internes et publics créés et théorisés pour l\'écosystème Akeli.',
    category: 'vision'
  },
  {
    fileName: 'Vision_personnel.md',
    title: 'Ma Vision Personnelle (Curtis)',
    desc: 'Le document intime du fondateur sur ses motivations profondes, ses responsabilités et son ambition financière et sociale.',
    category: 'vision'
  },

  // Category: business (Modèle & Expansion)
  {
    fileName: 'AKELI_MODE_FAN.md',
    title: 'Spécifications du Mode Fan',
    desc: 'Règles d\'observance des 90/10 et mécanisme technique du soutien direct de 1€/mois par abonné.',
    category: 'business'
  },
  {
    fileName: 'AKELI_MARCHES_EXPANSION.md',
    title: 'Stratégie de Marché & Expansion',
    desc: 'Plan de déploiement à long terme vers d\'autres diasporas et vers le continent africain.',
    category: 'business'
  },
  {
    fileName: 'AKELI_MODELE_CREATEUR.md',
    title: 'Le Modèle Créateur Akeli',
    desc: 'Analyse économique de la rémunération au repas pour le créateur standard vs le créateur en Mode Fan.',
    category: 'business'
  },
  {
    fileName: 'AKELI_NICHES.md',
    title: 'Analyse Fine des Niches Diaspora',
    desc: 'Contraintes spécifiques des sous-groupes de notre audience (sportifs, étudiants, soignants de nuit).',
    category: 'business'
  },
  {
    fileName: 'AKELI_PERSONAS_UTILISATEURS.md',
    title: 'Personas Utilisateurs Détaillés',
    desc: 'Fiches biographiques complètes et problématiques de santé spécifiques à chacun de nos personas.',
    category: 'business'
  },
  {
    fileName: 'AKELI_STRATEGIE_COMMUNAUTE.md',
    title: 'Stratégie d\'Acquisition Organique',
    desc: 'Bâtir un réseau de confiance sans dépendre des canaux d\'attention payants traditionnels.',
    category: 'business'
  },
  {
    fileName: 'AKELI_STRATEGIE_CREATEUR.md',
    title: 'Stratégie Créateurs & Recrutement',
    desc: 'Comment onboarder les créateurs culinaires et les transformer en partenaires de confiance d\'Akeli.',
    category: 'business'
  },
  {
    fileName: 'SESSION_SYNTHESIS.md',
    title: 'Synthèse Brute de Session',
    desc: 'Prise de notes et décisions prises lors des ateliers de cadrage de mars 2026.',
    category: 'business'
  },

  // Category: comm (Communication & Cibles)
  {
    fileName: 'AKELI_COMMUNICATION_CREATEUR.md',
    title: 'Charte de Communication Créateur',
    desc: 'Comment les créateurs partenaires doivent structurer leur communication et leur image publique pour Akeli.',
    category: 'comm'
  },
  {
    fileName: 'AKELI_AXES_CONTENU.md',
    title: 'Axes de Contenu & Ligne Éditoriale',
    desc: 'Exemples concrets de narration pour les réseaux sociaux, basés sur l\'émotion collective et le pragmatisme.',
    category: 'comm'
  },
  {
    fileName: 'AKELI_LIVE_PHASE1_PLAN_FR_EN.md',
    title: 'Plan de Lancement Live (Phase 1)',
    desc: 'Objectifs initiaux de lancement public et étapes clés de la phase de test.',
    category: 'comm'
  },
  {
    fileName: 'AKELI_LIVE_PHASE1_PLAN_V2_FR_EN.md',
    title: 'Plan de Lancement Live V2',
    desc: 'Version mise à jour de la stratégie de lancement opérationnelle après retours d\'audits.',
    category: 'comm'
  }
]

const SLIDES_PHASES = [
  {
    category: 'AKELI CORP • CADRAGE',
    title: 'Stratégie des Phases & Communication',
    type: 'title',
    content: `
      <div class="slide-title-layout">
        <span class="slide-badge">DOCUMENT INTERNE • MARS 2026</span>
        <h1 class="slide-mega-title">Pourquoi Akeli communique comme il le fait — et pas autrement.</h1>
        <p class="slide-author">Auteur : Curtis, Fondateur d'Akeli</p>
      </div>
    `
  },
  {
    category: 'PHASE 0 • CHANGEMENT DE PARADIGME',
    title: 'De la friction à l\'accumulation de confiance',
    type: 'split',
    content: `
      <div class="slide-grid-2col">
        <div class="slide-col">
          <h4 class="col-title color-platform">L'Ancien Modèle</h4>
          <span class="col-subtitle">La conversion par friction</span>
          <ul class="slide-bullets">
            <li><strong>Publicité intrusive :</strong> Créer une émotion forte mais éphémère.</li>
            <li><strong>Landing page forcée :</strong> Forcer le clic et la décision à froid.</li>
            <li><strong>Méfiance :</strong> L'interaction est verticale et unilatérale.</li>
            <li><strong>Volume nécessaire :</strong> Taux de conversion faible compensé par la masse.</li>
          </ul>
        </div>
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">Le Nouveau Modèle</h4>
          <span class="col-subtitle">La conversion par accumulation</span>
          <ul class="slide-bullets">
            <li><strong>Présence régulière :</strong> Bâtir une familiarité constante dans le temps.</li>
            <li><strong>Confiance progressive :</strong> Rendre la décision d'achat naturelle.</li>
            <li><strong>Légitimité :</strong> Chaque contenu dépose une couche de crédibilité.</li>
            <li><strong>Landing page de confirmation :</strong> Confirmer une décision déjà prise.</li>
          </ul>
        </div>
      </div>
    `
  },
  {
    category: 'PHASE 0.5 • VISION DES RÉSEAUX',
    title: 'Les réseaux sociaux comme lieu de rassemblement',
    type: 'text',
    content: `
      <p class="slide-lead">Le besoin de la diaspora est préexistant. Nous ne le créons pas, nous y répondons. Les réseaux sont un espace de parole, pas un panneau publicitaire.</p>
      <div class="slide-grid-3col">
        <div class="slide-mini-card">
          <div class="mini-card-icon">🔐</div>
          <h5>Espace de reconnaissance</h5>
          <p>L'utilisateur découvre que son décalage a un nom et qu'il n'est pas seul.</p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon">💬</div>
          <h5>Espace de parole</h5>
          <p>Chaque commentaire contribue à enrichir l'intelligence culinaire collective.</p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon">🤝</div>
          <h5>Rassemblement horizontal</h5>
          <p>Les abonnés échangent entre eux, créant le lien communautaire.</p>
        </div>
      </div>
    `
  },
  {
    category: 'PRINCIPIEL • MARKETING RELATIONNEL',
    title: 'La Règle des 7 Contacts',
    type: 'text',
    content: `
      <blockquote class="slide-blockquote">
        "Un contenu isolé ne convertit pas. Une présence constante convertit."
      </blockquote>
      <div class="slide-grid-2col" style="margin-top: 20px;">
        <div class="slide-text-block">
          <h5>Déposer des couches</h5>
          <p>Chaque contact n'a pas à vendre. Il dépose une couche de familiarité, une couche de crédibilité, une couche de reconnaissance. La somme produit la confiance.</p>
        </div>
        <div class="slide-text-block">
          <h5>Fréquence > Intensité</h5>
          <p>Le bon contenu est celui qui reste en tête. Mieux vaut 7 expositions simples et justes qu'une seule publicité spectaculaire mais oubliée le lendemain.</p>
        </div>
      </div>
    `
  },
  {
    category: 'STRATÉGIE • LES DEUX JAMBES',
    title: 'Jambe 1 (La Niche) & Jambe 2 (Les Résultats)',
    type: 'split',
    content: `
      <div class="slide-grid-2col">
        <div class="slide-col">
          <h4 class="col-title color-infra">Jambe 1 : La Niche Diaspora</h4>
          <span class="col-subtitle">Maintenant — Immédiat</span>
          <ul class="slide-bullets">
            <li><strong>Ancrage :</strong> Réalité sociologique et marché identifiable.</li>
            <li><strong>Action :</strong> Donne à Akeli le droit d'entrer dans la conversation.</li>
            <li><strong>Crédibilité :</strong> Construit la familiarité de marque initiale.</li>
            <li><strong>Sécurité :</strong> Éviter le discours identitaire trop clivant.</li>
          </ul>
        </div>
        <div class="slide-col">
          <h4 class="col-title color-gold">Jambe 2 : Preuve par les Résultats</h4>
          <span class="col-subtitle">Après 6 mois de données</span>
          <ul class="slide-bullets">
            <li><strong>Ancrage :</strong> Taux d'observance réels mesurés sur l'application.</li>
            <li><strong>Action :</strong> Donne à Akeli une place unique sur le marché.</li>
            <li><strong>Crédibilité :</strong> Preuve objective, vérité tranquille.</li>
            <li><strong>Sécurité :</strong> Ne pas promettre de résultats avant d'avoir les données.</li>
          </ul>
        </div>
      </div>
    `
  },
  {
    category: 'STRATÉGIE • LA PORTE D\'ENTRÉE',
    title: 'Pourquoi s\'adresser d\'abord à la diaspora ?',
    type: 'text',
    content: `
      <div class="slide-grid-2col" style="align-items: center; height: 100%;">
        <div>
          <ul class="slide-bullets-large">
            <li><strong>Le marché le plus mal servi :</strong> Aucun outil existant ne comprend leur cuisine.</li>
            <li><strong>Le marché le plus identifiable :</strong> Fiches et réalités sociologiques précises.</li>
            <li><strong>Facile à convaincre :</strong> Le décalage est si fort que la reconnaissance suffit.</li>
            <li><strong>Données riches :</strong> Permet de poser les bases de la "Preuve par les Résultats".</li>
          </ul>
        </div>
        <div class="slide-highlight-box">
          <h4>La diaspora n'est pas la destination finale.</h4>
          <p>C'est la porte d'entrée universelle qui rend possible la validation de notre modèle de réalignment avant expansion.</p>
        </div>
      </div>
    `
  },
  {
    category: 'PRINCIPIEL • GRANULARITÉ',
    title: 'La granularité est supérieure au générique',
    type: 'split',
    content: `
      <div class="slide-grid-2col">
        <div class="slide-col">
          <h4 class="col-title">Contenu Générique</h4>
          <p class="slide-desc">Chercher à plaire à tout le monde pour maximiser la portée.</p>
          <ul class="slide-bullets">
            <li>Reconnaissance faible ("c'est sympa").</li>
            <li>Mémorisation faible (le contenu glisse).</li>
            <li>Faible taux de partage organique.</li>
            <li>Ne construit pas de relation durable.</li>
          </ul>
        </div>
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">Contenu Granulaire</h4>
          <p class="slide-desc">S'adresser précisément à un profil et une réalité vécue.</p>
          <ul class="slide-bullets">
            <li>Reconnaissance forte ("c'est exactement ma vie").</li>
            <li>Mémorisation forte (le contenu reste en tête).</li>
            <li>Partage organique élevé ("tu dois voir ça").</li>
            <li>Contribution relationnelle majeure.</li>
          </ul>
        </div>
      </div>
    `
  },
  {
    category: 'STRATÉGIE • VOIX DE MARQUE',
    title: 'La carte des 5 registres émotionnels',
    type: 'text',
    content: `
      <p class="slide-lead" style="margin-bottom: 16px;">La constance exige de la variété. Nous activons alternativement 5 registres pour bâtir une relation complète.</p>
      <div class="slide-registers-list">
        <div class="register-item"><span class="reg-num">1</span><div><strong>La reconnaissance :</strong> "C'est exactement ma vie" (Soignante de nuit, décalage semaine).</div></div>
        <div class="register-item"><span class="reg-num">2</span><div><strong>La curiosité :</strong> "Je ne savais pas ça" (Manioc d'Amazonie, fufu universel).</div></div>
        <div class="register-item"><span class="reg-num">3</span><div><strong>La fierté :</strong> "Ma cuisine est forte" (La cuisine africaine a nourri l'Inde).</div></div>
        <div class="register-item"><span class="reg-num">4</span><div><strong>L'interrogation :</strong> "Je n'y avais pas pensé" (Mon alimentation travaille-t-elle pour moi ?).</div></div>
        <div class="register-item"><span class="reg-num">5</span><div><strong>La surprise :</strong> "Vraiment ?" (70% des adultes intolérants au lactose, mil en Afrique).</div></div>
      </div>
    `
  },
  {
    category: 'VUE D\'ENSEMBLE • SYSTÈME',
    title: 'Comment l\'architecture s\'articule',
    type: 'text',
    content: `
      <div class="slide-system-flow">
        <div class="flow-step">
          <span class="step-icon">⏱️</span>
          <h6>Constance (7 contacts)</h6>
          <p>Crée le terrain de jeu</p>
        </div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-step">
          <span class="step-icon">🎯</span>
          <h6>Granularité (Spécifique)</h6>
          <p>Produit la mémorisation</p>
        </div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-step">
          <span class="step-icon">🎨</span>
          <h6>5 Registres Émotionnels</h6>
          <p>Bâtit une relation riche</p>
        </div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-step">
          <span class="step-icon">🚀</span>
          <h6>Deux Jambes (Données)</h6>
          <p>Assure la légitimité finale</p>
        </div>
      </div>
      <div class="slide-flow-footer">
        <p class="highlight-gold">&there4; La conversion arrive naturellement, elle n'est pas forcée.</p>
      </div>
    `
  },
  {
    category: 'STRATÉGIE • CRITÈRES D\'ÉVALUATION',
    title: 'Changer la mesure de succès des contenus',
    type: 'split',
    content: `
      <div class="slide-grid-2col">
        <div class="slide-col">
          <h4 class="col-title color-platform">Mauvaises questions</h4>
          <ul class="slide-bullets">
            <li>Ce contenu a-t-il généré des inscriptions immédiates ?</li>
            <li>Pourquoi ce contenu n'a pas eu plus de vues ?</li>
            <li>Ce contenu parle-t-il à assez de monde ?</li>
            <li>Avons-nous publié quelque chose de viral ?</li>
          </ul>
        </div>
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">Bonnes questions</h4>
          <ul class="slide-bullets">
            <li>Ce contenu a-t-il contribué à la relation ?</li>
            <li>Quel registre émotionnel ce contenu a-t-il activé ?</li>
            <li>Ce contenu parle-t-il précisément à qui il doit parler ?</li>
            <li>Avons-nous maintenu notre présence cette semaine ?</li>
          </ul>
        </div>
      </div>
    `
  }
]

const SLIDES_LIVE_V1 = [
  {
    category: 'LIVE AKELI · PHASE 1 (SUPPORT PRO)',
    title: 'Vision & Fondations d\'Akeli',
    type: 'title',
    content: `
      <div class="slide-title-layout">
        <span class="slide-badge">SUPPORT DE PRÉSENTATION • MARS 2026</span>
        <h1 class="slide-mega-title">Live Phase 1 : Vision & Fondations</h1>
        <p class="slide-author">Une conversation — pas une présentation. Zoom · 60–75 min</p>
      </div>
    `
  },
  {
    category: 'BLOC 2 • LE PROBLÈME QU\'ON NE NOMME JAMAIS',
    title: 'Le décalage de la cuisine de la diaspora',
    type: 'split',
    content: `
      <div class="slide-grid-3col">
        <div class="slide-mini-card">
          <div class="mini-card-icon color-platform">🔄</div>
          <h5>01. La Désynchronisation</h5>
          <p>La cuisine africaine a été conçue pour des corps actifs et des climats chauds. Elle rencontre aujourd'hui une vie sédentaire en Europe. Ce n'est pas la cuisine qui est le problème — c'est le décalage.</p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon color-platform">📱</div>
          <h5>02. Le Vide des Outils</h5>
          <p>Les applications de nutrition classiques ne proposent que du quinoa et du poulet grillé. Rien ne parle le langage culinaire de la diaspora. Personne n'adresse ce problème sérieusement.</p>
        </div>
        <div class="slide-mini-card highlight-col">
          <div class="mini-card-icon color-gold">🌍</div>
          <h5>03. Un Problème Universel</h5>
          <p>La France, l'Inde, la Corée ou les États-Unis vivent leur propre version de cette rupture. La diaspora africaine n'est pas seule. Akeli commence ici car le besoin y est le plus urgent.</p>
        </div>
      </div>
    `
  },
  {
    category: 'BLOC 3 • LES TROIS PROFILS DE LA DIASPORA',
    title: 'À qui s\'adresse la plateforme Akeli ?',
    type: 'split',
    content: `
      <div class="slide-grid-3col">
        <div class="slide-mini-card">
          <div class="mini-card-icon">🍲</div>
          <h5>Le Primo-arrivant (35-55 ans)</h5>
          <p>Il mange et cuisine africain. Pas de crise identitaire. Son problème : personne ne lui a dit que son alimentation traditionnelle devait s'adapter à son rythme de vie sédentaire en Europe.</p>
        </div>
        <div class="slide-mini-card highlight-col">
          <div class="mini-card-icon">🏃</div>
          <h5>Le Déraciné (15-35 ans)</h5>
          <p>Né ou arrivé très jeune, intégré en France. Il cherche la praticité : comment habiter la cuisine de ses parents au quotidien sans friction et de manière simple.</p>
        </div>
        <div class="slide-mini-card" style="opacity: 0.6;">
          <div class="mini-card-icon">📢</div>
          <h5>Le Diasporant Identitaire</h5>
          <p>Bruyant sur les réseaux, parle de retour aux sources mais sa fidélité produit/usage est fragile. Akeli ne structure pas son produit ou sa communication autour de ce profil.</p>
        </div>
      </div>
    `
  },
  {
    category: 'BLOC 4 • CE QU\'EST AKELI (ET CE QU\'IL N\'EST PAS)',
    title: 'Une approche basée sur le Réalignment',
    type: 'split',
    content: `
      <blockquote class="slide-blockquote">
        "Tu n'as pas à choisir entre qui tu es et comment tu veux te sentir."
      </blockquote>
      <div class="slide-grid-2col" style="margin-top: 1rem;">
        <div class="slide-col">
          <h4 class="col-title color-platform">Un régime classique…</h4>
          <ul class="slide-bullets">
            <li>Part du principe que tu manges mal.</li>
            <li>Impose une rupture avec ta culture.</li>
            <li>Culpabilise, contraint et frustre.</li>
            <li>Échoue inévitablement à long terme.</li>
          </ul>
        </div>
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">Le Réalignment Akeli…</h4>
          <ul class="slide-bullets">
            <li>Considère que ton alimentation n'est pas l'ennemie.</li>
            <li>Ajuste les proportions sans changer qui tu es.</li>
            <li>Respecte l'histoire et le métabolisme du corps.</li>
            <li>Synchronise ton alimentation avec ton mode de vie.</li>
          </ul>
        </div>
      </div>
    `
  },
  {
    category: 'BLOC 4 • CE QU\'EST AKELI (ET CE QU\'IL N\'EST PAS)',
    title: 'Valeurs fondamentales de la plateforme',
    type: 'split',
    content: `
      <div class="slide-grid-2col">
        <div class="slide-col">
          <h4 class="col-title color-platform">Ce qu'Akeli n'est pas</h4>
          <ul class="slide-bullets">
            <li>❌ Pas une application de comptage de calories.</li>
            <li>❌ Pas un régime restrictif ou temporaire.</li>
            <li>❌ Pas un mouvement politique ou culturel.</li>
            <li>❌ Pas une énième solution miracle à la mode.</li>
            <li>❌ Pas une agence ou plateforme d'influenceurs food.</li>
          </ul>
        </div>
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">Ce qu'Akeli est</h4>
          <ul class="slide-bullets">
            <li>✨ Un espace où le savoir culinaire ancestral a de la valeur.</li>
            <li>✨ Un lieu de réalignment, pas de punition ou correction.</li>
            <li>✨ La modernité (pgvector) au service de la reconnexion.</li>
            <li>✨ Un projet construit main dans la main avec les créateurs.</li>
            <li>✨ Une alternative saine, honnête et paisible.</li>
          </ul>
        </div>
      </div>
    `
  },
  {
    category: 'BLOC 5 • LE CRÉATEUR AKELI',
    title: 'Qu\'est-ce qu\'un créateur Akeli ?',
    type: 'split',
    content: `
      <p class="slide-lead">La grand-mère qui a adapté le ndolé au marché parisien pendant 40 ans détient un savoir culinaire qu'aucun nutritionniste n'a produit.</p>
      <div class="slide-grid-2col" style="margin-top: 1rem;">
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">Un créateur Akeli est…</h4>
          <ul class="slide-bullets">
            <li>Quelqu'un qui partage simplement ce qu'il sait cuisiner.</li>
            <li>Un expert de sa réalité quotidienne et de sa niche.</li>
            <li>Rémunéré équitablement à la consommation réelle de ses plats.</li>
            <li>Authentique, ancré dans le vécu et le réel.</li>
          </ul>
        </div>
        <div class="slide-col">
          <h4 class="col-title color-platform">Un créateur n'est pas…</h4>
          <ul class="slide-bullets">
            <li>Un influenceur superficiel ou commercial.</li>
            <li>Un expert théorique en nutrition ou diplômé.</li>
            <li>Obligé d'avoir une immense communauté pour démarrer.</li>
            <li>Un simple vendeur d'abonnements ou de publicité.</li>
          </ul>
        </div>
      </div>
    `
  },
  {
    category: 'BLOC 6 • ÉCHANGE ET OUVERTURE',
    title: 'Échange ouvert avec les participants',
    type: 'split',
    content: `
      <p class="slide-lead" style="text-align: center;">Le bloc le plus important du live : écouter plus qu'on ne parle.</p>
      <div class="slide-grid-3col" style="margin-top: 1rem;">
        <div class="slide-mini-card">
          <div class="mini-card-icon">🙋</div>
          <h5>Question 1</h5>
          <p class="highlight-gold" style="font-style: italic; font-size: 1.1rem; line-height: 1.4; margin-top: 0.5rem;">
            "Est-ce que l'un d'entre vous a personnellement vécu ce décalage dont on parle ?"
          </p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon">🍲</div>
          <h5>Question 2</h5>
          <p class="highlight-gold" style="font-style: italic; font-size: 1.1rem; line-height: 1.4; margin-top: 0.5rem;">
            "Quel plat traditionnel vous manque le plus dans votre quotidien actuel ?"
          </p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon">🚫</div>
          <h5>Question 3</h5>
          <p class="highlight-gold" style="font-style: italic; font-size: 1.1rem; line-height: 1.4; margin-top: 0.5rem;">
            "Qu'est-ce qui vous a retenu de partager votre cuisine jusqu'à maintenant ?"
          </p>
        </div>
      </div>
    `
  },
  {
    category: 'BLOC 7 • CLÔTURE',
    title: 'Une invitation à nous rejoindre',
    type: 'split',
    content: `
      <blockquote class="slide-blockquote">
        "Ce qu'on construit ensemble, c'est un espace où votre savoir a de la place. Si ça vous parle, la prochaine étape est simple — on se retrouve."
      </blockquote>
      <div class="slide-grid-3col" style="margin-top: 1.5rem;">
        <div class="slide-mini-card" style="border-color: rgba(239, 68, 68, 0.2);">
          <div class="mini-card-icon" style="color: #ef4444;">✕</div>
          <h5>Pas de pression</h5>
          <p>Aucun call-to-action agressif ni sentiment d'urgence artificielle.</p>
        </div>
        <div class="slide-mini-card" style="border-color: rgba(239, 68, 68, 0.2);">
          <div class="mini-card-icon" style="color: #ef4444;">✕</div>
          <h5>Pas de « sign up » forcé</h5>
          <p>On n'impose pas d'inscription immédiate pendant le live.</p>
        </div>
        <div class="slide-mini-card" style="border-color: rgba(239, 68, 68, 0.2);">
          <div class="mini-card-icon" style="color: #ef4444;">✕</div>
          <h5>Pas de fausses promesses</h5>
          <p>Aucune promesse excessive de transformation magique ou rapide.</p>
        </div>
      </div>
    `
  },
  {
    category: 'POSTURE • RAPPELS POUR L\'ANIMATEUR',
    title: 'Les règles de posture d\'Akeli',
    type: 'split',
    content: `
      <div class="slide-grid-2col">
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">La Vérité Tranquille</h4>
          <p>Garder son calme en toutes circonstances. Éviter les superlatifs, l'excitation forcée ou le ton marketing traditionnel.</p>
          <h4 class="col-title color-gold" style="margin-top: 1.5rem;">Exposer — ne pas prescrire</h4>
          <p>Un fait ou une observation est posé sur la table. La conclusion et le choix appartiennent entièrement au membre.</p>
        </div>
        <div class="slide-col">
          <h4 class="col-title color-platform">La Règle des 20% / 80%</h4>
          <p>L'animateur parle 20% du temps. L'échange et les partages des participants occupent les 80% restants.</p>
          <h4 class="col-title color-platform" style="margin-top: 1.5rem;">Le langage simple</h4>
          <p>Si une phrase ou un argument ne peut pas être dit naturellement en mangeant avec un ami, elle doit être reformulée immédiatement.</p>
        </div>
      </div>
    `
  }
];

const SLIDES_LIVE_V2 = [
  {
    category: 'LIVE AKELI · PHASE 1 V2 (ZOOM CRÉATEURS)',
    title: 'Les gens ont besoin de ce que tu sais faire',
    type: 'title',
    content: `
      <div class="slide-title-layout">
        <span class="slide-badge">SUPPORT DE PRÉSENTATION • VERSION CRÉATEURS</span>
        <h1 class="slide-mega-title">Les gens ont besoin de ce que tu sais faire.</h1>
        <p class="slide-author">Zoom de Lancement · 30–40 min · Mars 2026</p>
      </div>
    `
  },
  {
    category: '01 • LE BESOIN EXISTE',
    title: 'Un marché entier non adressé par la nutrition',
    type: 'split',
    content: `
      <p class="slide-lead">Des millions de personnes consomment quotidiennement une cuisine que tous les outils modernes de nutrition ignorent royalement.</p>
      <div class="slide-grid-3col" style="margin-top: 1rem;">
        <div class="slide-mini-card">
          <div class="mini-card-icon">👩‍⚕️</div>
          <h5>La soignante de la diaspora</h5>
          <p>Elle rentre chez elle à 21h fatiguée. Elle veut manger un plat réconfortant qu'elle connaît, mais aucun outil ne l'aide à l'équilibrer de manière réaliste.</p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon">🎓</div>
          <h5>L'étudiant au budget serré</h5>
          <p>Il mange africain avec 50€ par mois. Il ne trouve aucune ressource pour concilier ses contraintes financières, son patrimoine et sa santé.</p>
        </div>
        <div class="slide-mini-card highlight-col">
          <div class="mini-card-icon">🏃</div>
          <h5>L'athlète de la diaspora</h5>
          <p>Il veut manger ses plats traditionnels sans compromettre son apport en protéines ou sa performance sportive. Personne n'a construit d'outil pour lui.</p>
        </div>
      </div>
    `
  },
  {
    category: '02 • TU CONNAIS TA NICHE',
    title: 'Ton vécu et ton savoir sont une expertise irremplaçable',
    type: 'split',
    content: `
      <div class="slide-grid-2col">
        <div class="slide-col highlight-col">
          <h4 class="col-title color-gold">Ce que tu as déjà</h4>
          <ul class="slide-bullets">
            <li><strong>La connaissance intime :</strong> Tu comprends la vie de ta niche de l'intérieur car tu la partages au quotidien.</li>
            <li><strong>Des recettes spécifiques :</strong> Des secrets culinaires de famille que personne d'autre ne sait adapter ou équilibrer.</li>
            <li><strong>Une réalité de vie partagée :</strong> Un lien de confiance horizontal instantané avec ton audience.</li>
          </ul>
        </div>
        <div class="slide-col">
          <h4 class="col-title color-platform">Ce dont tu n'as pas besoin</h4>
          <ul class="slide-bullets">
            <li>❌ Pas besoin d'être un chef étoilé ou un professionnel.</li>
            <li>❌ Pas besoin de dizaines de milliers d'abonnés sur Instagram ou TikTok.</li>
            <li>❌ Pas besoin d'avoir un diplôme en nutrition ou en marketing.</li>
          </ul>
        </div>
      </div>
    `
  },
  {
    category: '03 • CE SAVOIR VAUT QUELQUE CHOSE',
    title: 'Une rémunération basée sur la consommation réelle',
    type: 'split',
    content: `
      <p class="slide-lead">Le savoir culinaire a toujours nourri les communautés. Akeli fait en sorte qu'il nourrisse aussi dignement le créateur qui le transmet.</p>
      <div class="slide-grid-3col" style="margin-top: 1rem;">
        <div class="slide-mini-card">
          <div class="mini-card-icon">📈</div>
          <h5>Pas au like ou à la vue</h5>
          <p>Pas de course aux algorithmes ou de création effrénée de contenus éphémères pour plaire aux régies publicitaires.</p>
        </div>
        <div class="slide-mini-card highlight-col">
          <div class="mini-card-icon">💶</div>
          <h5>À la consommation réelle</h5>
          <p>Chaque fois qu'un membre valide un repas issu de tes recettes dans son plan hebdomadaire, tu perçois une rémunération directe et honnête.</p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon">🛡️</div>
          <h5>Un actif durable</h5>
          <p>Tes recettes restent disponibles et continuent de générer un revenu récurrent passif au fil des mois pour ta communauté.</p>
        </div>
      </div>
    `
  },
  {
    category: '04 • ÉCHANGE & INVITATION',
    title: 'Construisons l\'espace dont ta communauté a besoin',
    type: 'split',
    content: `
      <blockquote class="slide-blockquote">
        "Ce qu'on construit, c'est un espace où votre savoir a de la place et de la valeur. Si ce soir vous vous êtes reconnu — on se retrouve."
      </blockquote>
      <div class="slide-grid-3col" style="margin-top: 1.5rem;">
        <div class="slide-mini-card">
          <div class="mini-card-icon">👥</div>
          <h5>Question 1</h5>
          <p style="font-style: italic; font-size: 1rem; line-height: 1.4; margin-top: 0.5rem;">
            "Est-ce qu'il y a une niche spécifique représentée dans la salle ce soir ?"
          </p>
        </div>
        <div class="slide-mini-card">
          <div class="mini-card-icon">🚀</div>
          <h5>Question 2</h5>
          <p style="font-style: italic; font-size: 1rem; line-height: 1.4; margin-top: 0.5rem;">
            "Qu'est-ce qui vous a motivé à nous rejoindre pour ce lancement ?"
          </p>
        </div>
        <div class="slide-mini-card highlight-col">
          <div class="mini-card-icon">🍲</div>
          <h5>Question 3</h5>
          <p style="font-style: italic; font-size: 1rem; line-height: 1.4; margin-top: 0.5rem;">
            "Quel plat est pour vous synonyme de lien communautaire fort ?"
          </p>
        </div>
      </div>
    `
  }
];

const SLIDE_DECKS = {
  phases: SLIDES_PHASES,
  live_v1: SLIDES_LIVE_V1,
  live_v2: SLIDES_LIVE_V2
};

const AXES_DATA = {
  axe1: {
    title: 'Axe I : Enjeux Socioculturels',
    subtitle: 'Fonction : ATTENTION — Faire reconnaître une réalité vécue',
    lead: 'Cet axe accroche parce qu\'il nomme des réalités que les gens vivent sans les avoir jamais entendues formulées clairement. La reconnaissance est immédiate et puissante.',
    cards: [
      {
        id: 'I.1',
        title: 'La désynchronisation alimentaire',
        idea: 'Nous mangeons en un repas ce que nos ancêtres mangeaient un jour de fête. Et nous faisons beaucoup moins d\'effort physique. Nos cuisines traditionnelles ont été conçues pour des corps actifs dans des contextes précis. La vie moderne a tout changé — sauf ce qu\'on mange.',
        story: 'Le thiéboudienne du pêcheur vs. le thiéboudienne du cadre parisien — même plat, corps complètement différents. Les régimes échouent car ils s\'attaquent à la mauvaise cible (se priver plutôt que s\'adapter).',
        debates: [
          'Le décalage entre métabolisme ancestral et vie sédentaire urbaine.',
          'Pourquoi la frustration et la culpabilité des régimes ne fonctionnent pas.',
          'Comment corriger le décalage sans sanctionner sa culture.'
        ]
      },
      {
        id: 'I.2',
        title: 'Les trois profils de la diaspora',
        idea: 'La diaspora africaine n\'est pas un bloc homogène mais un archipel de réalités différentes. Trois profils coexistent avec des besoins nutritionnels non adressés.',
        story: 'Primo-arrivants (repas trad exclusifs mais non validés diététiquement), Déracinés (veulent retrouver les goûts de leur enfance mais manquent de temps/savoir-faire), et Identitaires (recherche d\'idéal mais usage fragile).',
        debates: [
          'Les problématiques de santé et de sédentarité spécifiques à chaque profil.',
          'Pourquoi les applications classiques ignorent les primo-arrivants.',
          'Comment Akeli crée une solution unifiée pour ces vécus.'
        ]
      },
      {
        id: 'I.3',
        title: 'Le problème global de la modernité',
        idea: 'La désynchronisation alimentaire n\'est pas un problème de diaspora. C\'est le problème nutritionnel de la modernité — universel, transversal, qui s\'aggrave sur tous les continents.',
        story: 'La France (gastronomie devenue industrielle), les USA (obésité de masse), l\'Inde (diabète sur une cuisine pourtant sophistiquée), l\'Asie de l\'Est (le mukbang comme réponse à la solitude urbaine des repas).',
        debates: [
          'La modernité industrielle comme ennemie de notre horloge biologique.',
          'Pourquoi les solutions globales échouent face à des particularités locales.',
          'Ce que signifie "combattre la modernité par la modernité".'
        ]
      },
      {
        id: 'I.4',
        title: 'Les niches spécifiques',
        idea: 'Identifier une niche avec précision crée une connexion immédiate et profonde avec ceux qui la vivent en décrivant leur quotidien.',
        story: 'La soignante (12h debout, a besoin de protéines et de repas anti-inflammatoires), la jeune pro (sédentaire de bureau, culpabilité alimentaire double), l\'athlète (performance construite par défaut sur des modèles occidentaux).',
        debates: [
          'L\'alimentation africaine adaptée au travail physique intense.',
          'Comment manger sainement quand on travaille dans un bureau parisien.',
          'Pourquoi la cuisine d\'origine peut être une arme de performance sportive.'
        ]
      },
      {
        id: 'I.5',
        title: 'L\'adaptation biologique',
        idea: 'Notre corps s\'adapte à ce qu\'il mange sur des générations. Manger ce pour quoi il est biologiquement préparé est une question de physiologie, pas seulement de culture.',
        story: 'Les Japonais (flore intestinale adaptée à la digestion des algues), les Européens (tolérance au lactose qui est une anomalie génétique mondiale chez 70% des adultes), l\'impact du cortisol urbain sur la digestion.',
        debates: [
          'Pourquoi les applications occidentales échouent sur les métabolismes de la diaspora.',
          'Le microbiote et l\'adaptation digestive culturelle.',
          'Manger pour son corps en respectant son héritage biologique.'
        ]
      }
    ]
  },
  axe2: {
    title: 'Axe II : Ouverture des Horizons Culinaires',
    subtitle: 'Fonction : INTEREST — Révéler l\'inattendu dans le connu',
    lead: 'Cet axe maintient l\'engagement en montrant ce que les gens ne savaient pas sur quelque chose qu\'ils croyaient connaître. Il transforme la fierté passive en curiosité active.',
    cards: [
      {
        id: 'II.1',
        title: 'La cuisine comme système vivant',
        idea: 'La cuisine africaine n\'est pas un patrimoine figé à préserver — c\'est une intelligence culinaire vivante qui a toujours su s\'adapter et absorber le changement.',
        story: 'L\'histoire du manioc : arrivé du bassin amazonien au 16e siècle, toxique à l\'état brut, il a été adopté et détoxifié par fermentation/séchage pour devenir un pilier continental. C\'est de l\'ingéniosité active.',
        debates: [
          'Qu\'est-ce qui définit une cuisine : ses ingrédients ou ses logiques ?',
          'Le maïs, la tomate, le piment : tous venus d\'ailleurs, tous devenus africains.',
          'Comment la cuisine traditionnelle transforme l\'étranger en familier.'
        ]
      },
      {
        id: 'II.2',
        title: 'La structure plutôt que la recette',
        idea: 'Le fufu n\'est pas une recette figée — c\'est une structure (base féculente + liant + texture). Cette structure traverse le continent et s\'adapte aux ressources locales.',
        story: 'La structure fufu peut utiliser l\'igname ou le plantain, mais s\'adapte en Europe avec le panais, le chou-fleur ou le céleri-rave tout en conservant le geste et la texture.',
        debates: [
          'La tradition comme cadre et la créativité locale comme contenu.',
          'Ce que "respecter une recette" veut réellement dire.',
          'Les structures adaptables des grands plats (mafé, thiéboudienne).'
        ]
      },
      {
        id: 'II.3',
        title: 'L\'ingrédient de demain',
        idea: 'Si la cuisine africaine a toujours intégré et transformé les ingrédients venus d\'ailleurs, quelles seront ses prochaines absorptions pour allier santé et écologie ?',
        story: 'Pistes d\'avenir : le tempeh (fermentation proche du néré/soumbala), les légumineuses locales européennes (pois chiches, lentilles), les algues (compatibles bouillons), et le moringa (superfood africain sous-exploité).',
        debates: [
          'Quels ingrédients modernes peuvent s\'intégrer naturellement aux plats traditionnels.',
          'La fermentation traditionnelle comme pont vers de nouveaux aliments.',
          'Comment concilier écologie locale et authenticité gustative.'
        ]
      },
      {
        id: 'II.4',
        title: 'Le paradoxe des cuisines importées',
        idea: 'Les cuisines asiatiques servies en Occident ont été massivement dénaturées pour plaire aux Européens. La cuisine africaine a le potentiel d\'arriver avec son authenticité intacte.',
        story: 'Le modèle des restaurants asiatiques occidentalisés vs l\'authenticité vierge de la cuisine africaine. Elle peut s\'adapter aux contraintes nutritionnelles sans se trahir car l\'adaptation fait partie de son ADN.',
        debates: [
          'Qu\'est-ce que l\'authenticité culinaire sur une plateforme d\'usage ?',
          'Pourquoi la cuisine africaine a un potentiel universel commercial vierge.',
          'Adapter sans dénaturer : la ligne de crête d\'Akeli.'
        ]
      },
      {
        id: 'II.5',
        title: 'Créer les nouvelles modes',
        idea: 'Les grandes chaînes de fast food s\'inspirent de la cuisine africaine sans inclure les créateurs, la culture ou la santé. Il est temps que la communauté prenne le contrôle de ses modes.',
        story: 'L\'appropriation commerciale des goûts et des fritures sans la conscience nutritionnelle. Akeli redonne le pouvoir aux créateurs d\'écrire les règles de la tendance de demain.',
        debates: [
          'La cuisine africaine sur le point de devenir mainstream : qui va en écrire les règles ?',
          'Inventer les recettes africaines urbaines de demain (accessibles, rapides, saines).',
          'Comment le digital peut protéger et propulser le patrimoine culinaire.'
        ]
      },
      {
        id: 'II.6',
        title: 'Quand l\'Afrique a nourri le monde',
        idea: 'La cuisine africaine n\'a pas seulement absorbé ce qui venait d\'ailleurs, elle a exporté des solutions vitales qui ont changé l\'histoire de peuples entiers de manière invisible.',
        story: 'Le mil (originaire d\'Afrique, introduit en Inde où il a sauvé des millions de vies de la famine), le couscous (plat préféré des Français, réussite culinaire totale), la technique de la semoule.',
        debates: [
          'L\'histoire invisible du mil africain comme sauveur de l\'Inde.',
          'Ce que le succès populaire du couscous en France révèle sur le potentiel de notre cuisine.',
          'Comment valoriser et documenter l\'apport culinaire de l\'Afrique au monde.'
        ]
      }
    ]
  },
  axe3: {
    title: 'Axe III : Ambition et Opportunités',
    subtitle: 'Fonction : DESIRE — Déclencher le passage à l\'action',
    lead: 'Cet axe s\'adresse directement au créateur potentiel. Il traduit la vision en opportunité concrète, honnête et accessible, en créant l\'envie d\'agir sans promesse excessive.',
    cards: [
      {
        id: 'III.1',
        title: 'La valeur du savoir culinaire',
        idea: 'Pour la première fois, ce que tu sais cuisiner au quotidien peut générer un revenu récurrent prévisible, basé sur l\'impact nutritionnel réel et non sur l\'attention.',
        story: 'La différence entre la rémunération aux likes/vues des géants de la tech (YouTube/TikTok) et la rémunération à l\'usage réel. Vos recettes deviennent un actif durable qui s\'apprécie avec le temps.',
        debates: [
          'Pourquoi la rémunération à la vue maintient les créateurs dans la précarité.',
          'La notion d\'actif culinaire par rapport au contenu éphémère.',
          'Comment valoriser économiquement un savoir-faire familial quotidien.'
        ]
      },
      {
        id: 'III.2',
        title: 'La faible barrière d\'entrée',
        idea: 'Tu n\'as pas besoin d\'avoir un studio de tournage professionnel ou des millions d\'abonnés. Une petite audience ultra-ciblée et engagée suffit largement.',
        story: 'L\'algorithme de TikTok distribue le contenu selon la pertinence de la niche, pas selon la taille du compte. Avoir une niche très précise est un avantage structurel pour bâtir une communauté.',
        debates: [
          'Pourquoi les micro-créateurs ont un meilleur taux de conversion.',
          'Comment identifier et parler à sa niche naturelle de l\'intérieur.',
          'Les principes simples pour débuter sur les réseaux sans matériel lourd.'
        ]
      },
      {
        id: 'III.3',
        title: 'L\'audience diététique & Mode Fan',
        idea: 'Le Mode Fan crée une audience diététique fidèle : des utilisateurs qui cuisinent vos repas chaque semaine et vous allouent directement 1€/mois de leur abonnement.',
        story: 'Un modèle de revenu garanti et stable, indépendant des algorithmes. La règle des 90/10 verrouille la fidélité : les abonnés Fan cuisinent majoritairement vos recettes.',
        debates: [
          'La différence majeure entre une audience qui regarde et une audience qui mange.',
          'Comment stabiliser ses revenus grâce au Mode Fan.',
          'Bâtir une relation de confiance et de co-construction au quotidien.'
        ]
      },
      {
        id: 'III.4',
        title: 'La transparence des résultats',
        idea: 'Après 6 mois de récolte de données d\'observance, Akeli affiche publiquement les taux de réussite réels des programmes. La preuve remplace la promesse.',
        story: 'La nutrition en ligne est saturée de faux influenceurs aux promesses miracles. Akeli valorise les créateurs authentiques dont les plats permettent des résultats réels et vérifiés.',
        debates: [
          'Pourquoi la transparence est le futur de l\'économie de la recommandation.',
          'Ce que change la publication des scores d\'efficacité pour les créateurs sérieux.',
          'Bâtir sa réputation sur des résultats de santé mesurés.'
        ]
      },
      {
        id: 'III.5',
        title: 'Une progression honnête et réaliste',
        idea: 'Akeli ne promet pas la richesse facile en 10 jours. Nous proposons une trajectoire réaliste sur 12 mois pour valoriser durablement votre savoir culinaire.',
        story: 'La progression type : 0-3 mois (constitution du catalogue de 30 recettes), 3-6 mois (premières consommations), 6-12 mois (premiers abonnés Fan, stabilisation), 12 mois+ (revenu complémentaire significatif).',
        debates: [
          'Pourquoi la patience éditoriale est indispensable.',
          'La différence entre une opportunité rapide et un actif à long terme.',
          'Les étapes clés pour ne pas décrocher lors des premiers mois.'
        ]
      }
    ]
  }
};

const PERSONAS = {
  p1: {
    title: 'Fatoumata — Le Primo-arrivant (35-50 ans)',
    role: 'Le Socle de l\'Authenticité',
    badgeClass: 'badge-p1',
    meta: {
      origin: 'Première génération (Cameroun/Sénégal)',
      diet: 'Cuisine traditionnelle africaine exclusive',
      health: 'Risques de diabète ou hypertension non adressés',
      tech: 'Usage basique (WhatsApp, Facebook)'
    },
    sections: {
      desc: 'Arrivée adulte en France, elle cuisine traditionnel pour toute sa famille. Son identité est claire et ses repères culinaires sont solides. Elle ne se sent pas concernée par les discours de "retour aux origines".',
      problem: 'Son métabolisme vit désormais dans une réalité sédentaire (climat froid, transports en commun, travail de bureau ou de garde assis). Les applications de nutrition classiques lui proposent du quinoa fade et ignorent sa cuisine, ce qui la pousse à décrocher.',
      solution: 'Akeli lui propose des recettes adaptées au climat et à son niveau d\'activité physique en conservant ses repères gustatifs et sans discours condescendant sur sa culture.'
    }
  },
  p2: {
    title: 'Idriss — Le Déraciné (15-35 ans)',
    role: 'Le Cœur du Volume',
    badgeClass: 'badge-p2',
    meta: {
      origin: 'Deuxième génération (né en France)',
      diet: 'Alimentation mixte (Fast-food, plats préparés, resto)',
      health: 'Alimentation déséquilibrée par manque de temps',
      tech: 'Usage intensif (TikTok, Instagram, applications)'
    },
    sections: {
      desc: 'Étudiant ou jeune professionnel actif, il a le goût formé par les plats traditionnels de sa mère, mais ne sait pas les cuisiner. Son alimentation est dominée par la simplicité industrielle.',
      problem: 'Il souhaite manger sainement mais refuse de renier ses souvenirs culinaires. Il manque de temps et d\'ustensiles complexes pour préparer les sauces traditionnelles mijotées pendant 3 heures.',
      solution: 'Akeli met à sa disposition des "recettes structurelles" simplifiées, rapides à cuisiner dans un studio parisien, tout en réintégrant ses repères aromatiques d\'enfance.'
    }
  },
  p3: {
    title: 'Kenza — L\'Identitaire (20-40 ans)',
    role: 'Le Relais de Lancement',
    badgeClass: 'badge-p3',
    meta: {
      origin: 'Seconde génération engagée',
      diet: 'Recherche active de cuisine "healthy" afro-centrée',
      health: 'Alimentation conscientisée et documentée',
      tech: 'Création de contenu, forte présence sur les réseaux'
    },
    sections: {
      desc: 'Très éduquée et active sur les réseaux sociaux, elle recherche une narration identitaire forte autour de l\'Afrique. Elle valorise le patrimoine culinaire publiquement.',
      problem: 'Elle est réceptive aux discours marketing mais volatile. Son ton peut parfois sembler moralisateur ou donner des leçons de vie, ce qui aliène les profils 1 et 2.',
      solution: 'Akeli l\'utilise comme relais d\'opinion et de visibilité initiale au lancement du produit, sans pour autant calquer son discours de marque sur sa narrative identitaire politique.'
    }
  }
}

// 2. DOM Elements & Logic

const SECTION_NAMES = {
  vision: 'Vision & Fondation',
  philosophy: 'Philosophie & Concepts',
  business: 'Modèle Économique',
  marketing: 'Marketing & Cibles',
  axes: 'Axes Éditoriaux',
  library: 'Bibliothèque Vault',
  presentation: 'Slides Stratégiques'
}

document.addEventListener('DOMContentLoaded', () => {
  setupNavigation()
  setupConceptsSection()
  setupBusinessSimulator()
  setupPersonaSwitcher()
  setupMobileMenu()
  setupDocViewer()
  setupLibrarySection()
  setupPresentationSection()
  setupAxesSection()
})

// Navigation logic (with sidebar and bottom tab bar synchronization)
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item, .bottom-nav-item')
  const sections = document.querySelectorAll('.content-section')
  const headerTitle = document.querySelector('.header-title-wrapper h1')

  // Helper to update active states across both nav lists
  const activateTab = (targetId) => {
    navItems.forEach(nav => {
      const href = nav.getAttribute('href').substring(1)
      if (href === targetId) {
        nav.classList.add('active')
      } else {
        nav.classList.remove('active')
      }
    })
    
    // Update active section
    sections.forEach(section => {
      if (section.id === targetId) {
        section.classList.add('active')
      } else {
        section.classList.remove('active')
      }
    })
    
    // Dynamically update the header title on mobile
    if (headerTitle && SECTION_NAMES[targetId]) {
      headerTitle.textContent = window.innerWidth <= 768 ? SECTION_NAMES[targetId] : 'Charte Stratégique'
    }
  }

  // Bind clicks
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault()
      
      const targetId = item.getAttribute('href').substring(1)
      activateTab(targetId)
      
      // Scroll to top of the content area
      document.querySelector('.sections-container').scrollTop = 0

      // Close mobile menu if open
      const sidebar = document.getElementById('sidebar')
      const backdrop = document.getElementById('sidebar-backdrop')
      if (sidebar && sidebar.classList.contains('open')) {
        sidebar.classList.remove('open')
        backdrop.classList.remove('active')
      }
    })
  })

  // Synchronize on resize
  window.addEventListener('resize', () => {
    const activeSection = document.querySelector('.content-section.active')
    if (activeSection && headerTitle) {
      const targetId = activeSection.id
      headerTitle.textContent = window.innerWidth <= 768 ? SECTION_NAMES[targetId] : 'Charte Stratégique'
    }
  })

  // Initial title set for default active tab
  const initialActive = document.querySelector('.content-section.active')
  if (initialActive) {
    activateTab(initialActive.id)
  }
}

// Mobile Menu toggle logic (sidebar drawer)
function setupMobileMenu() {
  const menuToggle = document.getElementById('menu-toggle')
  const sidebar = document.getElementById('sidebar')
  const backdrop = document.getElementById('sidebar-backdrop')

  if (!menuToggle || !sidebar || !backdrop) return

  menuToggle.addEventListener('click', () => {
    sidebar.classList.add('open')
    backdrop.classList.add('active')
  })

  backdrop.addEventListener('click', () => {
    sidebar.classList.remove('open')
    backdrop.classList.remove('active')
  })
}

// Setup Document Viewer backdrop and close click listeners
function setupDocViewer() {
  const closeBtn = document.getElementById('doc-viewer-close')
  const backdrop = document.getElementById('doc-viewer-backdrop')
  const viewer = document.getElementById('doc-viewer')

  if (!closeBtn || !backdrop || !viewer) return

  const closeViewer = () => {
    viewer.classList.remove('open')
    backdrop.classList.remove('active')
  }

  closeBtn.addEventListener('click', closeViewer)
  backdrop.addEventListener('click', closeViewer)
}

// Concepts Filter Logic
function setupConceptsSection() {
  const btnInternes = document.getElementById('btn-concepts-internes')
  const btnPublics = document.getElementById('btn-concepts-publics')
  const displayGrid = document.getElementById('concepts-display-grid')

  if (!displayGrid) return

  // Render function
  const renderConcepts = (filterType) => {
    displayGrid.innerHTML = ''
    
    const filtered = CONCEPTS.filter(c => c.type === filterType)
    
    filtered.forEach(c => {
      const card = document.createElement('div')
      card.className = 'concept-card'
      
      card.innerHTML = `
        <div class="concept-top-row">
          <h4 class="concept-name">${c.name}</h4>
          <span class="concept-label ${c.type === 'internal' ? 'label-internal' : 'label-public'}">
            ${c.type === 'internal' ? 'Interne' : 'Public'}
          </span>
        </div>
        <p class="concept-definition">${c.definition}</p>
        <div class="concept-context">
          <strong>Contexte :</strong> ${c.context}
          <div class="concept-footer">
            <span class="concept-file">📄 ${c.ref}</span>
            <span class="concept-read-link">Lire le document &rarr;</span>
          </div>
        </div>
      `
      
      // Bind click to open document drawer
      card.addEventListener('click', () => {
        openDocument(c.ref, c.name)
      })
      
      displayGrid.appendChild(card)
    })
  }

  // Bind Buttons
  btnInternes.addEventListener('click', () => {
    btnInternes.classList.add('active')
    btnPublics.classList.remove('active')
    renderConcepts('internal')
  })

  btnPublics.addEventListener('click', () => {
    btnPublics.classList.add('active')
    btnInternes.classList.remove('active')
    renderConcepts('public')
  })

  // Initial render
  renderConcepts('internal')
}

// Business Model Simulator
function setupBusinessSimulator() {
  const rangeSubs = document.getElementById('subscribers-range')
  const rangeFanPercent = document.getElementById('fan-percent-range')
  const rangeConsumption = document.getElementById('consumption-range')
  
  const valSubs = document.getElementById('subscribers-val')
  const valFanPercent = document.getElementById('fan-percent-val')
  const valConsumption = document.getElementById('consumption-val')
  
  const outputFan = document.getElementById('revenue-fan')
  const outputStandard = document.getElementById('revenue-standard')
  const outputTotal = document.getElementById('revenue-total')
  
  const labelFansCount = document.getElementById('fans-count')
  const labelStandardCount = document.getElementById('standard-count')
  const wrapperConsumption = document.getElementById('consumption-slider-wrapper')

  if (!rangeSubs) return

  const formatEuro = (val) => {
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }).format(val)
  }

  const updateSimulation = () => {
    const totalSubs = parseInt(rangeSubs.value)
    const fanPercent = parseInt(rangeFanPercent.value)
    const meals = parseInt(rangeConsumption.value)
    
    // Update Slider text labels
    valSubs.textContent = totalSubs
    valFanPercent.textContent = `${fanPercent}%`
    valConsumption.textContent = meals
    
    // Hide standard slider if 100% fan mode
    if (fanPercent === 100) {
      wrapperConsumption.classList.add('hidden')
    } else {
      wrapperConsumption.classList.remove('hidden')
    }

    // Calculations
    const fansCount = Math.round(totalSubs * (fanPercent / 100))
    const standardCount = totalSubs - fansCount
    
    // Fan mode: €1 guaranteed per user
    const revenueFan = fansCount * 1.00
    
    // Standard mode: (meals consumed / 90 meals) * €1
    const revenueStandard = standardCount * (meals / 90) * 1.00
    const totalRevenue = revenueFan + revenueStandard
    
    // Render Results
    outputFan.textContent = formatEuro(revenueFan)
    outputStandard.textContent = formatEuro(revenueStandard)
    outputTotal.textContent = formatEuro(totalRevenue)
    
    labelFansCount.textContent = `${fansCount} fans actifs`
    labelStandardCount.textContent = `${standardCount} abonnés standards`
  }

  // Listeners
  rangeSubs.addEventListener('input', updateSimulation)
  rangeFanPercent.addEventListener('input', updateSimulation)
  rangeConsumption.addEventListener('input', updateSimulation)

  // Initial update
  updateSimulation()
}

// Persona Switcher
function setupPersonaSwitcher() {
  const tabs = document.querySelectorAll('.persona-tab')
  const box = document.getElementById('persona-display-box')

  if (!box) return

  const renderPersona = (key) => {
    const data = PERSONAS[key]
    box.innerHTML = `
      <div class="persona-title-row">
        <h3>${data.title}</h3>
        <span class="persona-role-badge ${data.badgeClass}">${data.role}</span>
      </div>
      <div class="persona-attributes">
        <div class="persona-meta">
          <div class="meta-item">
            <span class="meta-label">Origine et génération</span>
            <span class="meta-val">${data.meta.origin}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Habitudes culinaires</span>
            <span class="meta-val">${data.meta.diet}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Problématique de santé</span>
            <span class="meta-val">${data.meta.health}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Usage de la technologie</span>
            <span class="meta-val">${data.meta.tech}</span>
          </div>
        </div>
        <div class="persona-details">
          <div class="detail-section">
            <h5>Description</h5>
            <p>${data.sections.desc}</p>
          </div>
          <div class="detail-section">
            <h5>Le Problème Métabolique Réel</h5>
            <p>${data.sections.problem}</p>
          </div>
          <div class="detail-section">
            <h5>La Solution Akeli</h5>
            <p>${data.sections.solution}</p>
          </div>
        </div>
      </div>
    `
  }

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'))
      tab.classList.add('active')
      const personaKey = tab.getAttribute('data-persona')
      renderPersona(personaKey)
    })
  })

  // Initial render (persona 1)
  renderPersona('p1')
}

// --- DOCUMENT VIEWER AND MARKDOWN PARSER LOGIC ---

function openDocument(fileName, title) {
  const viewer = document.getElementById('doc-viewer')
  const backdrop = document.getElementById('doc-viewer-backdrop')
  const body = document.getElementById('doc-viewer-body')
  const meta = document.getElementById('doc-viewer-meta')

  if (!viewer || !backdrop || !body || !meta) return

  // Show loading spinner
  body.innerHTML = `
    <div class="spinner-container">
      <div class="spinner"></div>
      <p>Chargement de ${title}...</p>
    </div>
  `
  meta.textContent = 'CHARGEMENT...'

  // Open drawer
  viewer.classList.add('open')
  backdrop.classList.add('active')

  // Fetch document
  fetch(`/docs/${fileName}`)
    .then(response => {
      if (!response.ok) {
        throw new Error(`Erreur ${response.status} : Impossible de charger le document.`)
      }
      return response.text()
    })
    .then(md => {
      // Calculate reading time (200 words per minute average)
      const wordCount = md.split(/\s+/).length
      const readTime = Math.ceil(wordCount / 200)
      meta.textContent = `DOCUMENT • ${readTime} MIN DE LECTURE`

      // Parse and display HTML
      const parsedHtml = parseMarkdown(md)
      body.innerHTML = `
        <article class="markdown-body">
          ${parsedHtml}
        </article>
      `
      
      // Scroll body back to top
      body.scrollTop = 0
    })
    .catch(err => {
      body.innerHTML = `
        <div class="error-container">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="error-icon"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <h4>Erreur de chargement</h4>
          <p>${err.message}</p>
          <button class="retry-btn" id="retry-btn">Réessayer</button>
        </div>
      `
      meta.textContent = 'ERREUR'
      
      // Bind retry button
      const retryBtn = document.getElementById('retry-btn')
      if (retryBtn) {
        retryBtn.addEventListener('click', () => {
          openDocument(fileName, title)
        })
      }
    })
}

// Custom Markdown-to-HTML parser
function parseMarkdown(md) {
  if (!md) return ''

  // Normalize line endings
  let text = md.replace(/\r\n/g, '\n')

  const lines = text.split('\n')
  const html = []
  let inList = false
  let inBlockquote = false

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()

    // Horizontal Rule
    if (line === '---') {
      if (inList) { html.push('</ul>'); inList = false }
      if (inBlockquote) { html.push('</blockquote>'); inBlockquote = false }
      html.push('<hr />')
      continue
    }

    // Headers
    if (line.startsWith('# ')) {
      if (inList) { html.push('</ul>'); inList = false }
      if (inBlockquote) { html.push('</blockquote>'); inBlockquote = false }
      html.push(`<h1>${line.substring(2)}</h1>`)
      continue
    }
    if (line.startsWith('## ')) {
      if (inList) { html.push('</ul>'); inList = false }
      if (inBlockquote) { html.push('</blockquote>'); inBlockquote = false }
      html.push(`<h2>${line.substring(3)}</h2>`)
      continue
    }
    if (line.startsWith('### ')) {
      if (inList) { html.push('</ul>'); inList = false }
      if (inBlockquote) { html.push('</blockquote>'); inBlockquote = false }
      html.push(`<h3>${line.substring(4)}</h3>`)
      continue
    }

    // Blockquote
    if (line.startsWith('> ')) {
      if (inList) { html.push('</ul>'); inList = false }
      if (!inBlockquote) {
        html.push('<blockquote>')
        inBlockquote = true
      }
      let content = line.substring(2)
      content = formatInline(content)
      html.push(`<p>${content}</p>`)
      continue
    } else if (inBlockquote && line === '') {
      if (i + 1 < lines.length && !lines[i + 1].trim().startsWith('> ')) {
        html.push('</blockquote>')
        inBlockquote = false
      }
      continue
    } else if (inBlockquote && !line.startsWith('> ')) {
      html.push('</blockquote>')
      inBlockquote = false
    }

    // Unordered List
    if (line.startsWith('- ') || line.startsWith('* ')) {
      if (!inList) {
        html.push('<ul>')
        inList = true
      }
      let content = line.substring(2)
      content = formatInline(content)
      html.push(`<li>${content}</li>`)
      continue
    }

    // Ordered List
    const orderedMatch = line.match(/^(\d+)\.\s+(.*)$/)
    if (orderedMatch) {
      if (inList) { html.push('</ul>'); inList = false }
      let content = orderedMatch[2]
      content = formatInline(content)
      html.push(`<div class="list-ordered-item"><span class="list-num">${orderedMatch[1]}</span><span class="list-text">${content}</span></div>`)
      continue
    }

    // Empty Line
    if (line === '') {
      if (inList) {
        html.push('</ul>')
        inList = false
      }
      continue
    }

    // Regular Paragraph
    if (inList) {
      html.push('</ul>')
      inList = false
    }
    const content = formatInline(line)
    html.push(`<p>${content}</p>`)
  }

  if (inList) html.push('</ul>')
  if (inBlockquote) html.push('</blockquote>')

  return html.join('\n')
}

// Inline formatting helper
function formatInline(text) {
  if (!text) return ''
  
  // Escaping simple HTML tags to avoid broken renderings
  let safeText = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

  // Re-allow specific inline HTML wrappers that our parser generates
  const restoreTags = (t) => {
    return t
      .replace(/&lt;strong&gt;/g, '<strong>')
      .replace(/&lt;\/strong&gt;/g, '</strong>')
      .replace(/&lt;em&gt;/g, '<em>')
      .replace(/&lt;\/em&gt;/g, '</em>')
      .replace(/&lt;code&gt;/g, '<code>')
      .replace(/&lt;\/code&gt;/g, '</code>')
      .replace(/&lt;a (.*?)&gt;/g, '<a $1>')
      .replace(/&lt;\/a&gt;/g, '</a>')
  }

  // Apply Markdown tags on safeText
  safeText = safeText.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
  safeText = safeText.replace(/\*(.*?)\*/g, '<em>$1</em>')
  safeText = safeText.replace(/`(.*?)`/g, '<code>$1</code>')
  safeText = safeText.replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" target="_blank" class="md-link">$1</a>')
  safeText = safeText.replace(/ → /g, ' &rarr; ')

  return restoreTags(safeText)
}

function setupLibrarySection() {
  const displayGrid = document.getElementById('library-display-grid')
  const categoriesContainer = document.getElementById('lib-categories-container')
  
  if (!displayGrid || !categoriesContainer) return

  const renderDocs = (filterCat) => {
    displayGrid.innerHTML = ''
    
    const filtered = filterCat === 'all' 
      ? DOCUMENTS 
      : DOCUMENTS.filter(d => d.category === filterCat)
      
    filtered.forEach(d => {
      const card = document.createElement('div')
      card.className = 'doc-card'
      
      let catLabel = ''
      let catClass = ''
      if (d.category === 'vision') { catLabel = 'Vision & Philosophie'; catClass = 'cat-vision' }
      else if (d.category === 'business') { catLabel = 'Modèle & Expansion'; catClass = 'cat-business' }
      else if (d.category === 'comm') { catLabel = 'Communication & Cibles'; catClass = 'cat-comm' }

      card.innerHTML = `
        <div class="doc-card-top">
          <h4 class="doc-card-title">${d.title}</h4>
          <p class="doc-card-desc">${d.desc}</p>
        </div>
        <div class="doc-card-footer">
          <span class="doc-card-cat ${catClass}">${catLabel}</span>
          <span class="doc-card-read">Lire le document &rarr;</span>
        </div>
      `
      
      card.addEventListener('click', () => {
        openDocument(d.fileName, d.title)
      })
      
      displayGrid.appendChild(card)
    })
  }

  // Bind category button clicks
  const buttons = categoriesContainer.querySelectorAll('.toggle-btn')
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      buttons.forEach(b => b.classList.remove('active'))
      btn.classList.add('active')
      const cat = btn.getAttribute('data-lib-cat')
      renderDocs(cat)
    })
  })

  // Initial render
  renderDocs('all')
}

function setupPresentationSection() {
  const screen = document.getElementById('slide-screen')
  const dotsContainer = document.getElementById('slide-dots')
  const prevBtn = document.getElementById('slide-prev')
  const nextBtn = document.getElementById('slide-next')
  const deckToggle = document.getElementById('deck-selector-toggle')

  if (!screen || !dotsContainer || !prevBtn || !nextBtn) return

  let activeDeckId = 'phases'
  let currentSlide = 0

  const getSlides = () => SLIDE_DECKS[activeDeckId] || []

  const renderSlide = (index) => {
    const slides = getSlides()
    if (!slides.length) return

    currentSlide = index
    const slide = slides[index]
    
    // Render slide layout
    screen.innerHTML = `
      <div class="slide-card">
        <div class="slide-header">
          <span class="slide-category">${slide.category}</span>
          <span class="slide-number">SLIDE ${String(index + 1).padStart(2, '0')} / ${String(slides.length).padStart(2, '0')}</span>
        </div>
        <div class="slide-content-area">
          ${slide.type !== 'title' ? `<h3 class="slide-title">${slide.title}</h3>` : ''}
          ${slide.content}
        </div>
        <div class="slide-footer">
          <span>AKELI CORP • Vault Stratégique</span>
          <span>CURTIS • CONFIDENTIEL</span>
        </div>
      </div>
    `
    
    // Enable/disable buttons
    prevBtn.disabled = index === 0
    nextBtn.disabled = index === slides.length - 1
    
    // Update dots
    const dots = dotsContainer.querySelectorAll('.slide-dot')
    dots.forEach((dot, idx) => {
      if (idx === index) {
        dot.classList.add('active')
      } else {
        dot.classList.remove('active')
      }
    })
  }

  const initDots = () => {
    const slides = getSlides()
    dotsContainer.innerHTML = ''
    slides.forEach((_, idx) => {
      const dot = document.createElement('div')
      dot.className = 'slide-dot'
      if (idx === 0) dot.className += ' active'
      dot.addEventListener('click', () => {
        renderSlide(idx)
      })
      dotsContainer.appendChild(dot)
    })
  }

  // Bind deck switcher buttons
  if (deckToggle) {
    const buttons = deckToggle.querySelectorAll('.toggle-btn')
    buttons.forEach(btn => {
      btn.addEventListener('click', () => {
        buttons.forEach(b => b.classList.remove('active'))
        btn.classList.add('active')
        activeDeckId = btn.getAttribute('data-deck')
        
        // Reset and re-render for new deck
        initDots()
        renderSlide(0)
      })
    })
  }

  // Bind button clicks
  prevBtn.addEventListener('click', () => {
    if (currentSlide > 0) {
      renderSlide(currentSlide - 1)
    }
  })

  nextBtn.addEventListener('click', () => {
    const slides = getSlides()
    if (currentSlide < slides.length - 1) {
      renderSlide(currentSlide + 1)
    }
  })

  // Bind Keyboard Navigation (Left/Right arrow keys)
  document.addEventListener('keydown', (e) => {
    const presSection = document.getElementById('presentation')
    if (presSection && presSection.classList.contains('active')) {
      const slides = getSlides()
      if (e.key === 'ArrowRight' && currentSlide < slides.length - 1) {
        renderSlide(currentSlide + 1)
      } else if (e.key === 'ArrowLeft' && currentSlide > 0) {
        renderSlide(currentSlide - 1)
      }
    }
  })

  // Initial render
  initDots()
  renderSlide(0)
}

function setupAxesSection() {
  const switcherToggle = document.getElementById('axes-switcher-toggle')
  const axesLeadBox = document.getElementById('axes-lead-box')
  const axesCardContainer = document.getElementById('axes-card-container')
  const axesPrev = document.getElementById('axes-prev')
  const axesNext = document.getElementById('axes-next')
  const axesDots = document.getElementById('axes-dots')

  if (!switcherToggle || !axesLeadBox || !axesCardContainer || !axesPrev || !axesNext || !axesDots) return

  let activeAxeId = 'axe1'
  let currentCardIndex = 0
  let totalCards = 0

  const populateCards = () => {
    const axe = AXES_DATA[activeAxeId]
    axesLeadBox.innerHTML = `<p>${axe.lead}</p>`
    
    totalCards = axe.cards.length
    axesCardContainer.innerHTML = ''
    
    axe.cards.forEach((card, index) => {
      const cardEl = document.createElement('div')
      cardEl.className = 'axes-card'
      cardEl.innerHTML = `
        <div class="axes-card-header">
          <span class="axes-card-id">${card.id}</span>
          <h4 class="axes-card-title">${card.title}</h4>
        </div>
        <div class="axes-card-content">
          <div>
            <div class="axes-section-title">Idée Centrale</div>
            <div class="axes-idea-panel">${card.idea}</div>
          </div>
          <div>
            <div class="axes-section-title">Récit / Illustration</div>
            <div class="axes-story-panel">${card.story}</div>
          </div>
          <div>
            <div class="axes-section-title">Pistes de Débat</div>
            <ul class="axes-debates-list">
              ${card.debates.map(d => `<li>${d}</li>`).join('')}
            </ul>
          </div>
        </div>
        <div class="axes-card-footer">
          <span>AKELI • Ligne Éditoriale</span>
          <span>Carte ${index + 1} / ${totalCards}</span>
        </div>
      `
      axesCardContainer.appendChild(cardEl)
    })
  }

  const renderCard = (index) => {
    currentCardIndex = index
    axesCardContainer.style.transform = `translateX(-${currentCardIndex * 100}%)`
    
    // Enable/disable buttons
    axesPrev.disabled = currentCardIndex === 0
    axesNext.disabled = currentCardIndex === totalCards - 1
    
    // Update dots
    const dots = axesDots.querySelectorAll('.slide-dot')
    dots.forEach((dot, idx) => {
      if (idx === currentCardIndex) {
        dot.classList.add('active')
      } else {
        dot.classList.remove('active')
      }
    })
  }

  const initDots = () => {
    axesDots.innerHTML = ''
    for (let idx = 0; idx < totalCards; idx++) {
      const dot = document.createElement('div')
      dot.className = 'slide-dot'
      if (idx === 0) dot.className += ' active'
      dot.addEventListener('click', () => {
        renderCard(idx)
      })
      axesDots.appendChild(dot)
    }
  }

  // Bind switcher buttons
  const buttons = switcherToggle.querySelectorAll('.toggle-btn')
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      buttons.forEach(b => b.classList.remove('active'))
      btn.classList.add('active')
      activeAxeId = btn.getAttribute('data-axe')
      
      // Reset card index, re-populate cards and dots
      populateCards()
      initDots()
      renderCard(0)
    })
  })

  // Bind controls
  axesPrev.addEventListener('click', () => {
    if (currentCardIndex > 0) {
      renderCard(currentCardIndex - 1)
    }
  })

  axesNext.addEventListener('click', () => {
    if (currentCardIndex < totalCards - 1) {
      renderCard(currentCardIndex + 1)
    }
  })

  // Bind Keyboard Navigation
  document.addEventListener('keydown', (e) => {
    const axesSection = document.getElementById('axes')
    if (axesSection && axesSection.classList.contains('active')) {
      if (e.key === 'ArrowRight' && currentCardIndex < totalCards - 1) {
        renderCard(currentCardIndex + 1)
      } else if (e.key === 'ArrowLeft' && currentCardIndex > 0) {
        renderCard(currentCardIndex - 1)
      }
    }
  })

  // Initial render
  populateCards()
  initDots()
  renderCard(0)
}

