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
  marketing: 'Marketing & Cibles'
}

document.addEventListener('DOMContentLoaded', () => {
  setupNavigation()
  setupConceptsSection()
  setupBusinessSimulator()
  setupPersonaSwitcher()
  setupMobileMenu()
  setupDocViewer()
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
