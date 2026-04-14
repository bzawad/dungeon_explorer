// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { Howl, Howler } from "howler"

// =============================================================================
// IMAGE PRELOADING SYSTEM
// =============================================================================

/**
 * Comprehensive image preloading system with controlled concurrency, retry logic, and smart caching
 * This helps prevent image loading failures when the app uses many small images
 */
class ImagePreloader {
  constructor(options = {}) {
    this.maxConcurrency = options.maxConcurrency || 5
    this.maxRetries = options.maxRetries || 3
    this.retryDelay = options.retryDelay || 1000
    this.cacheTTL = options.cacheTTL || (24 * 60 * 60 * 1000) // 24 hours default
    this.storageKey = 'dungeonImageCache'
    this.versionKey = 'dungeonImageCacheVersion'
    this.currentVersion = '1.3' // Increment when image list or preload order changes (1.3: tilesets first)

    this.loadedImages = new Set()
    this.failedImages = new Set()
    this.cachedImages = new Set()
    this.totalImages = 0
    this.processedImages = 0
    this.onProgress = options.onProgress || (() => { })
    this.onComplete = options.onComplete || (() => { })

    // Load cache state from localStorage
    this.loadCacheState()
  }

  /**
   * Load cached image state from localStorage
   */
  loadCacheState() {
    try {
      const cacheData = localStorage.getItem(this.storageKey)
      const cacheVersion = localStorage.getItem(this.versionKey)

      if (cacheData && cacheVersion === this.currentVersion) {
        const parsed = JSON.parse(cacheData)
        const now = Date.now()

        // Check if cache hasn't expired
        if (parsed.timestamp && (now - parsed.timestamp) < this.cacheTTL) {
          this.cachedImages = new Set(parsed.images || [])
          console.log(`📦 Found ${this.cachedImages.size} cached images (TTL valid)`)
          return
        } else {
          console.log('⏰ Image cache expired, will refresh')
        }
      } else if (cacheVersion !== this.currentVersion) {
        console.log('🔄 Image cache version changed, will refresh')
      }

      // Clear expired or invalid cache
      this.clearCache()
    } catch (error) {
      console.warn('Failed to load image cache:', error)
      this.clearCache()
    }
  }

  /**
   * Save cache state to localStorage
   */
  saveCacheState() {
    try {
      const cacheData = {
        timestamp: Date.now(),
        images: Array.from(this.loadedImages)
      }

      localStorage.setItem(this.storageKey, JSON.stringify(cacheData))
      localStorage.setItem(this.versionKey, this.currentVersion)
      console.log(`💾 Saved ${this.loadedImages.size} images to cache`)
    } catch (error) {
      console.warn('Failed to save image cache:', error)
    }
  }

  /**
   * Clear cache from localStorage
   */
  clearCache() {
    try {
      localStorage.removeItem(this.storageKey)
      localStorage.removeItem(this.versionKey)
      this.cachedImages.clear()
    } catch (error) {
      console.warn('Failed to clear image cache:', error)
    }
  }

  /**
   * Check if an image is already available in browser cache
   */
  async isImageCached(src) {
    return new Promise((resolve) => {
      const img = new Image()

      // Set up a timeout to avoid hanging
      const timeout = setTimeout(() => {
        img.onload = null
        img.onerror = null
        resolve(false)
      }, 100) // Quick check - if it takes longer than 100ms, assume not cached

      img.onload = () => {
        clearTimeout(timeout)
        resolve(true)
      }

      img.onerror = () => {
        clearTimeout(timeout)
        resolve(false)
      }

      img.src = src
    })
  }

  /**
   * Generate comprehensive list of all images used in the app.
   * Order matters: tilesets and map_links are first so they are in cache
   * before the dungeon grid renders (CSS background-images), avoiding
   * inconsistent tiled image loading.
   */
  generateImageList() {
    const images = []

    // Tileset images first – used for every tile background (floor, wall, corridor, shrub)
    const tilesets = [
      'desert.png', 'blue_crystals.png', 'brown_cavern.png', 'calm_water.png',
      'cobblestone.png', 'damp_stone.png', 'dark_cobblestone.png', 'dark_jungle.png',
      'dark_square_stones.png', 'dark_stone_with_vines.png', 'dirt_and_grass.png',
      'dirt.png', 'gray_cavern.png', 'green_shrubs.png', 'haunted_forest_shrubs.png',
      'haunted_ground.png', 'iron_grates.png', 'iron_plates.png', 'jungle_path.png',
      'light_brown_cavern.png', 'light_cobblestone.png', 'light_cracked_stone.png',
      'light_stones.png', 'marble.png', 'mountains.png', 'mystical.png',
      'pleasant_woods.png', 'red_brown_cavern.png', 'red_dirt.png', 'river_water.png',
      'sand_stone.png', 'sand.png', 'south_west.png', 'sparse_grass.png',
      'square_stones.png', 'white_stones.png', 'wood_boards.png', 'wood_boards2.png'
    ]
    tilesets.forEach(img => images.push(`/images/tilesets/${img}`))

    // Map link images second – entrances, exits, waypoints, stairs (visible on first paint)
    const mapLinks = [
      'cavern_entrance1.png', 'cavern_exit1.png', 'cavern_stairs1.png', 'cavern_stairs2.png',
      'cavern_stairs3.png', 'cavern_stairs4.png', 'dungeon_entrance1.png', 'dungeon_exit1.png',
      'dungeon_stairs1.png', 'dungeon_stairs2.png', 'dungeon_stairs3.png', 'dungeon_stairs4.png',
      'outdoor_waypoint1.png', 'outdoor_waypoint2.png', 'outdoor_waypoint3.png', 'outdoor_waypoint4.png'
    ]
    mapLinks.forEach(img => images.push(`/images/map_links/${img}`))

    // UI Images (main directory)
    const uiImages = [
      'bread.png', 'break_door.png', 'bullseye.png', 'cancel.png', 'castle.png',
      'chat.png', 'cheese.png', 'chest.png', 'corridor.png', 'd20.png',
      'damage.png', 'door.png', 'doorway.png', 'down_arrow.png', 'empty_coin_purse.png',
      'evade.png', 'explosion.png', 'eye.png', 'fog.png', 'gold.png',
      'grapes.png', 'green_checkmark.png', 'healing_potion.png', 'heart.png',
      'hourglass.png', 'left_arrow.png', 'lock.png', 'lockpicks.png',
      'magnifying_glass.png', 'open_lock.png', 'open_scroll.png', 'pile_of_bones.png',
      'printer.png', 'reset.png', 'right_arrow.png', 'room.png', 'scale.png',
      'secret.png', 'shield.png', 'shortsword.png', 'special_item.png',
      'stairway.png', 'swords.png', 'torch.png', 'trap.png', 'up_arrow.png',
      'victory.png', 'xp.png'
    ]
    uiImages.forEach(img => images.push(`/images/${img}`))

    // Character sprites (directional)
    const characterSprites = [
      'rogue1_0.png', 'rogue1_1.png', 'rogue1_2.png', 'rogue1_3.png',
      'rogue2_0.png', 'rogue2_1.png', 'rogue2_2.png', 'rogue2_3.png'
    ]
    characterSprites.forEach(img => images.push(`/images/characters/${img}`))

    // Door images (16 variations)
    for (let i = 1; i <= 16; i++) {
      const doorNum = String(i).padStart(2, '0')
      images.push(`/images/doors/door${doorNum}.png`)
    }

    // Monster images
    const monsters = [
      'acolyte.png', 'animated_armor.png', 'ant.png', 'apprentice.png', 'archmage.png',
      'assassin.png', 'bandit.png', 'bat_swarm.png', 'beastman.png', 'berserker.png',
      'black_pudding.png', 'blob_fish.png', 'boar.png', 'brain_eater.png', 'bugbear.png',
      'cave_brute.png', 'cave_creeper.png', 'centaur.png', 'centipede_swarm.png', 'chimera.png',
      'clay_golem.png', 'cloaker.png', 'cultist_fighter.png', 'cultist_mage.png', 'cyclops.png',
      'dark_elf.png', 'darkmantle.png', 'deep_gnome.png', 'doppelganger.png', 'drider.png',
      'drow_priestess.png', 'drow.png', 'druid.png', 'dryad.png', 'duergar.png',
      'efreeti.png', 'ettercap.png', 'evil_guard.png', 'evil_lizardfolk.png', 'evil_mage.png',
      'evil_piggy.png', 'fairy.png', 'female_druid.png', 'female_elf.png', 'flesh_golem.png',
      'gargoyle.png', 'gelatinous_cube.png', 'ghast.png', 'ghoul.png', 'giant_bat.png',
      'giant_centipede.png', 'giant_crab.png', 'giant_dung_beetle.png', 'giant_frog.png',
      'gibbering_mouther.png', 'gnoll.png', 'goblin_boss.png', 'goblin_scout.png',
      'goblin_shaman.png', 'goblin_warrior.png', 'god_of_all_multiverses.png', 'gorgon.png',
      'gorilla.png', 'grick.png', 'griffon.png', 'guard.png', 'harpy.png', 'hell_hound.png',
      'hobgoblin.png', 'hooded_acolyte.png', 'imp_devil.png', 'innkeeper.png', 'iron_golem.png',
      'kobold_defender.png', 'kobold_shaman.png', 'kobold_spearman.png', 'kobold_warlock.png',
      'lich.png', 'lizard_dude.png', 'lizardfolk.png', 'mage.png', 'maid.png', 'male_elf.png',
      'medusa.png', 'merchant.png', 'mimic.png', 'minotaur.png', 'moeshrooom.png', 'mummy.png',
      'mushroomfolk.png', 'night_hag.png', 'ogre.png', 'orc_boss.png', 'orc_chieftain.png',
      'orc.png', 'owlbear.png', 'possessed_head.png', 'rat.png', 'scary_face.png',
      'silent_ghost.png', 'skeleton.png', 'snow_ape.png', 'spider.png', 'stone_golem.png',
      'thug.png', 'town_guard.png', 'wailing_ghost.png', 'weald_hag.png', 'zombie_piggy.png',
      'zombie.png'
    ]
    monsters.forEach(img => images.push(`/images/monsters/${img}`))

    // Special feature images
    const specialFeatures = [
      'altar.png', 'barrel.png', 'bookcase.png', 'brazier.png', 'cage.png',
      'campfire.png', 'candle.png', 'chair.png', 'cobwebs.png', 'coffin.png',
      'cot.png', 'crate.png', 'crown.png', 'cupboard.png', 'dais.png',
      'debris.png', 'desk.png', 'fence.png', 'fireplace.png', 'fountain.png',
      'fungus.png', 'group_of_barrels.png', 'hut.png', 'lectern.png', 'logs.png',
      'magic_circle.png', 'magic_portal.png', 'mirror.png', 'mushrooms.png',
      'obelisk.png', 'pedestal.png', 'pile_of_chests.png', 'pile_of_weapons_and_armor.png',
      'pillar.png', 'pit.png', 'plant.png', 'pool.png', 'quicksand.png',
      'rocks.png', 'rubble.png', 'rug.png', 'sarcophagus.png', 'stack_of_books.png',
      'stack_of_crates.png', 'statue.png', 'stool.png', 'table.png', 'target.png',
      'tent.png', 'throne.png', 'torture_rack.png', 'treasure_pile.png', 'tree.png',
      'weapon_rack.png', 'well.png'
    ]
    specialFeatures.forEach(img => images.push(`/images/special_features/${img}`))

    return images
  }

  /**
   * Load a single image with retry logic
   */
  async loadImageWithRetry(src, retryCount = 0) {
    try {
      await this.loadSingleImage(src)
      this.loadedImages.add(src)
      return true
    } catch (error) {
      if (retryCount < this.maxRetries) {
        console.warn(`Failed to load ${src}, retrying (${retryCount + 1}/${this.maxRetries})`)
        await this.delay(this.retryDelay)
        return this.loadImageWithRetry(src, retryCount + 1)
      } else {
        console.error(`Failed to load ${src} after ${this.maxRetries} attempts`)
        this.failedImages.add(src)
        return false
      }
    }
  }

  /**
   * Load a single image and return a promise
   */
  loadSingleImage(src) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.onload = () => resolve(img)
      img.onerror = () => reject(new Error(`Failed to load ${src}`))
      img.src = src
    })
  }

  /**
   * Simple delay utility
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  /**
   * Process images in batches with controlled concurrency
   */
  async processImageBatch(images) {
    const results = []

    for (let i = 0; i < images.length; i += this.maxConcurrency) {
      const batch = images.slice(i, i + this.maxConcurrency)
      const batchPromises = batch.map(src => this.loadImageWithRetry(src))

      const batchResults = await Promise.all(batchPromises)
      results.push(...batchResults)

      this.processedImages += batch.length
      this.onProgress({
        processed: this.processedImages,
        total: this.totalImages,
        percentage: Math.round((this.processedImages / this.totalImages) * 100)
      })
    }

    return results
  }

  /**
 * Filter images to only load those that need loading
 */
  async filterImagesToLoad(allImages) {
    console.log(`🔍 Checking ${allImages.length} images for cache status...`)
    const imagesToLoad = []
    const alreadyCached = []

    // First check our localStorage cache
    for (const src of allImages) {
      if (this.cachedImages.has(src)) {
        alreadyCached.push(src)
        this.loadedImages.add(src) // Mark as loaded
      } else {
        imagesToLoad.push(src)
      }
    }

    console.log(`📦 ${alreadyCached.length} images found in cache, ${imagesToLoad.length} need checking/loading`)

    // For remaining images, quickly check if they're in browser cache
    const finalImagesToLoad = []
    if (imagesToLoad.length > 0) {
      console.log('🔍 Quick-checking browser cache for remaining images...')

      // Check in small batches to avoid overwhelming the browser
      const batchSize = 10
      for (let i = 0; i < imagesToLoad.length; i += batchSize) {
        const batch = imagesToLoad.slice(i, i + batchSize)
        const cacheChecks = await Promise.all(
          batch.map(async (src) => {
            const isCached = await this.isImageCached(src)
            if (isCached) {
              this.loadedImages.add(src)
              return null // Already cached
            }
            return src // Needs loading
          })
        )

        // Add non-null results to final load list
        finalImagesToLoad.push(...cacheChecks.filter(src => src !== null))
      }
    }

    console.log(`📦 Browser cache check complete: ${imagesToLoad.length - finalImagesToLoad.length} more found cached`)
    console.log(`🚀 Final result: ${finalImagesToLoad.length} images need loading`)

    return finalImagesToLoad
  }

  /**
   * Start preloading all images (with smart caching)
   */
  async preloadAll() {
    const allImages = this.generateImageList()

    // Filter to only load images that aren't already cached
    const imagesToLoad = await this.filterImagesToLoad(allImages)

    this.totalImages = allImages.length
    this.processedImages = allImages.length - imagesToLoad.length // Already processed cached ones

    if (imagesToLoad.length === 0) {
      console.log(`✅ All ${allImages.length} images already cached!`)
      this.onComplete({
        total: this.totalImages,
        loaded: this.loadedImages.size,
        failed: 0,
        duration: 0,
        failedImages: []
      })
      return
    }

    console.log(`🚀 Smart preload: Loading ${imagesToLoad.length} of ${allImages.length} images (${allImages.length - imagesToLoad.length} already cached)`)

    const startTime = Date.now()
    await this.processImageBatch(imagesToLoad)
    const endTime = Date.now()

    // Save the updated cache state
    this.saveCacheState()

    const summary = {
      total: this.totalImages,
      loaded: this.loadedImages.size,
      failed: this.failedImages.size,
      duration: endTime - startTime,
      failedImages: Array.from(this.failedImages),
      newlyLoaded: imagesToLoad.length,
      fromCache: allImages.length - imagesToLoad.length
    }

    console.log(`✅ Smart preloading completed:`, summary)
    this.onComplete(summary)

    return summary
  }

  /**
   * Verify all images are actually available (for LiveView validation)
   */
  async verifyImageAvailability() {
    const allImages = this.generateImageList()
    console.log(`🔍 Verifying availability of ${allImages.length} images...`)

    const unavailable = []
    const available = []

    // Quick check for all images
    const checkPromises = allImages.map(async (src) => {
      const isAvailable = await this.isImageCached(src)
      if (isAvailable) {
        available.push(src)
      } else {
        unavailable.push(src)
      }
    })

    await Promise.all(checkPromises)

    const result = {
      total: allImages.length,
      available: available.length,
      unavailable: unavailable.length,
      unavailableImages: unavailable
    }

    console.log(`📊 Image availability check:`, result)

    if (unavailable.length > 0) {
      console.log(`⚠️ ${unavailable.length} images are not available, will load them now`)
      // Load the missing images
      await this.processImageBatch(unavailable)
      this.saveCacheState()
    }

    return result
  }
}

// Global preloading state to prevent duplicate preloading
window.dungeonImagePreloading = window.dungeonImagePreloading || {
  started: false,
  completed: false,
  promise: null
}

// Create global preloader instance
const imagePreloader = new ImagePreloader({
  maxConcurrency: 5,
  maxRetries: 3,
  retryDelay: 1000,
  onProgress: (progress) => {
    // Show progress in console and update any UI elements
    if (progress.percentage % 20 === 0) {
      console.log(`🖼️ Dungeon images loading: ${progress.percentage}% (${progress.processed}/${progress.total})`)
    }

    // Update any loading indicators on the page
    const loadingIndicators = document.querySelectorAll('.image-preload-status')
    loadingIndicators.forEach(indicator => {
      indicator.textContent = `Loading images: ${progress.percentage}%`
    })
  },
  onComplete: (summary) => {
    window.dungeonImagePreloading.completed = true

    const newlyLoaded = summary.newlyLoaded || 0
    const fromCache = summary.fromCache || 0

    if (summary.failed > 0) {
      console.warn(`⚠️ Smart preloading completed with ${summary.failed} failures (${newlyLoaded} new, ${fromCache} cached, ${summary.duration}ms)`)
      console.log('Failed images:', summary.failedImages)
    } else if (newlyLoaded === 0) {
      console.log(`✅ All ${summary.total} images already cached! (${summary.duration}ms)`)
    } else {
      console.log(`✅ Smart preloading complete! ${newlyLoaded} newly loaded, ${fromCache} from cache (${summary.duration}ms)`)
    }

    // Update any loading indicators on the page
    const loadingIndicators = document.querySelectorAll('.image-preload-status')
    loadingIndicators.forEach(indicator => {
      if (summary.failed > 0) {
        indicator.textContent = `Images loaded (${summary.failed} failed)`
        indicator.style.color = '#f59e0b'
      } else if (newlyLoaded === 0) {
        indicator.textContent = 'All images cached!'
        indicator.style.color = '#10b981'
      } else {
        indicator.textContent = `Images ready! (${newlyLoaded} new)`
        indicator.style.color = '#10b981'
      }
    })
  }
})

// Function to start preloading (idempotent)
function startImagePreloading() {
  if (window.dungeonImagePreloading.started) {
    console.log('📦 Image preloading already in progress...')
    return window.dungeonImagePreloading.promise
  }

  console.log('🚀 Starting dungeon image preloading...')
  window.dungeonImagePreloading.started = true
  window.dungeonImagePreloading.promise = imagePreloader.preloadAll().catch(error => {
    console.error('💥 Image preloading system encountered an error:', error)
    window.dungeonImagePreloading.started = false // Allow retry on error
  })

  return window.dungeonImagePreloading.promise
}

// Start preloading immediately when the script loads
startImagePreloading()

// Expose utilities globally for debugging
window.dungeonImageUtils = {
  clearCache: () => {
    imagePreloader.clearCache()
    console.log('🗑️ Image cache cleared')
  },
  verifyImages: () => imagePreloader.verifyImageAvailability(),
  preloadAll: () => startImagePreloading(),
  getCacheInfo: () => {
    const cacheData = localStorage.getItem(imagePreloader.storageKey)
    if (cacheData) {
      const parsed = JSON.parse(cacheData)
      const now = Date.now()
      const age = now - parsed.timestamp
      const ageHours = Math.round(age / (1000 * 60 * 60) * 10) / 10
      return {
        cached: parsed.images?.length || 0,
        ageHours,
        expires: ageHours >= 24 ? 'expired' : `in ${24 - ageHours} hours`
      }
    }
    return { cached: 0, ageHours: 0, expires: 'no cache' }
  }
}

// =============================================================================
// LIVEVIEW HOOKS
// =============================================================================

// LiveView Hooks
let Hooks = {}

Hooks.ScreenSizeDetector = {
  mounted() {
    // Send initial screen size
    this.pushEvent("screen_size", { width: window.innerWidth })

    // Listen for window resize
    this.handleResize = () => {
      this.pushEvent("screen_size", { width: window.innerWidth })
    }
    window.addEventListener('resize', this.handleResize)

    // Listen for focus_map events from LiveView
    this.handleEvent("focus_map", () => {
      const dungeonMap = document.getElementById('dungeon-map')
      if (dungeonMap) {
        dungeonMap.focus()
        console.log("Focus restored to dungeon map")
      }
    })
  },

  destroyed() {
    window.removeEventListener('resize', this.handleResize)
  }
}

Hooks.AudioPlayer = {
  mounted() {
    // Initialize sound effects using Howler.js
    this.soundEffects = {
      fight: new Howl({
        src: ['/audio/fight.mp3'],
        volume: 0.7,
        preload: true
      }),
      player_hit: new Howl({
        src: ['/audio/player_hit.mp3'],
        volume: 0.7,
        preload: true
      }),
      player_miss: new Howl({
        src: ['/audio/player_miss.mp3'],
        volume: 0.7,
        preload: true
      }),
      monster_hit: new Howl({
        src: ['/audio/monster_hit.mp3'],
        volume: 0.7,
        preload: true
      }),
      monster_miss: new Howl({
        src: ['/audio/monster_miss.mp3'],
        volume: 0.7,
        preload: true
      }),
      death: new Howl({
        src: ['/audio/death.mp3'],
        volume: 0.7,
        preload: true
      }),
      coins: new Howl({
        src: ['/audio/coins.mp3'],
        volume: 0.7,
        preload: true
      }),
      door_open: new Howl({
        src: ['/audio/door_open.mp3'],
        volume: 0.3,
        preload: true
      }),
      click: new Howl({
        src: ['/audio/click.mp3'],
        volume: 0.7,
        preload: true
      }),
      chest_open: new Howl({
        src: ['/audio/chest_open.mp3'],
        volume: 0.3,
        preload: true
      }),
      pickup: new Howl({
        src: ['/audio/pickup.mp3'],
        volume: 0.8,
        preload: true
      }),
      stairs: new Howl({
        src: ['/audio/stairs.mp3'],
        volume: 0.7,
        preload: true
      }),
      orch_hit: new Howl({
        src: ['/audio/orch_hit.mp3'],
        volume: 0.5,
        preload: true
      }),
      banging: new Howl({
        src: ['/audio/banging.mp3'],
        volume: 0.7,
        preload: true
      }),
      dungeon_wanderer1: new Howl({
        src: ['/audio/dungeon_wanderer1.mp3'],
        volume: 0.2,
        preload: true,
        loop: false
      }),
      dungeon_wanderer2: new Howl({
        src: ['/audio/dungeon_wanderer2.mp3'],
        volume: 0.2,
        preload: true,
        loop: false
      }),
      dungeon_wanderer3: new Howl({
        src: ['/audio/dungeon_wanderer3.mp3'],
        volume: 0.2,
        preload: true,
        loop: false
      }),
      dungeon_wanderer4: new Howl({
        src: ['/audio/dungeon_wanderer4.mp3'],
        volume: 0.2,
        preload: true,
        loop: false
      }),
      dungeon_wanderer5: new Howl({
        src: ['/audio/dungeon_wanderer5.mp3'],
        volume: 0.2,
        preload: true,
        loop: false
      }),
      dungeon_death: new Howl({
        src: ['/audio/dungeon_death.mp3'],
        volume: 0.2,
        preload: true,
        loop: false
      }),
      dungeon_fight1: new Howl({
        src: ['/audio/dungeon_fight1.mp3'],
        volume: 0.2,
        preload: true,
        loop: false
      })
    }

    // Track if audio context has been initialized
    this.audioInitialized = false

    // Track which levels have had background music played
    this.levelsWithMusic = new Set()

    // Track current background music for resumption after combat
    this.currentBackgroundMusic = null
    this.backgroundMusicPosition = 0

    // Track current music state to prevent duplicate starts
    this.currentMusicState = 'none' // 'none', 'background', 'combat', 'death'

    // Listen for play audio events from LiveView
    this.handleEvent("play_audio", ({ sound, volume }) => {
      this.playSound(sound, volume)
    })

    // Listen for background music events from LiveView
    this.handleEvent("play_background_music", ({ level, theme }) => {
      this.playBackgroundMusic(level, theme)
    })

    // Listen for stop background music events from LiveView
    this.handleEvent("stop_background_music", () => {
      this.stopBackgroundMusic()
    })

    // Listen for death music events from LiveView
    this.handleEvent("play_death_music", () => {
      this.playDeathMusic()
    })

    // Listen for combat music events from LiveView
    this.handleEvent("play_combat_music", () => {
      this.playCombatMusic()
    })

    // Listen for resume background music events from LiveView
    this.handleEvent("resume_background_music", () => {
      this.resumeBackgroundMusic()
    })

    // Initialize audio context on first user interaction
    this.initializeAudioOnInteraction()

    console.log("AudioPlayer hook mounted with Howler.js")
  },

  initializeAudioOnInteraction() {
    const initializeAudio = () => {
      if (!this.audioInitialized) {
        // Resume the audio context (Howler handles this automatically)
        Howler.ctx && Howler.ctx.resume()
        this.audioInitialized = true
        console.log("Audio context initialized after user interaction")

        // Remove the event listeners since we only need to do this once
        document.removeEventListener('click', initializeAudio, true)
        document.removeEventListener('touchstart', initializeAudio, true)
        document.removeEventListener('keydown', initializeAudio, true)
      }
    }

    // Listen for any user interaction to initialize audio
    document.addEventListener('click', initializeAudio, true)
    document.addEventListener('touchstart', initializeAudio, true)
    document.addEventListener('keydown', initializeAudio, true)
  },

  playSound(soundName, volume = null) {
    // Ensure audio context is ready before playing
    if (!this.audioInitialized) {
      console.warn("Audio not yet initialized - waiting for user interaction")
      return
    }

    const sound = this.soundEffects[soundName]
    if (sound) {
      // Set volume if provided
      if (volume !== null) {
        sound.volume(volume)
      }

      // Play the sound
      sound.play()

      console.log(`Playing sound: ${soundName}`)
    } else {
      console.warn(`Sound not found: ${soundName}`)
    }
  },

  playBackgroundMusic(level, theme) {
    // Ensure audio context is ready before playing
    if (!this.audioInitialized) {
      console.warn("Audio not yet initialized - waiting for user interaction")
      return
    }

    // Create a unique key for this level and theme combination
    const levelKey = `${level}-${theme}`

    // Check if music has already been played for this level/theme
    if (this.levelsWithMusic.has(levelKey)) {
      console.log(`Background music already played for level ${level} (${theme})`)
      return
    }

    // Choose random music from all 5 wanderer tracks
    const wandererTracks = ['dungeon_wanderer1', 'dungeon_wanderer2', 'dungeon_wanderer3', 'dungeon_wanderer4', 'dungeon_wanderer5']
    const randomIndex = Math.floor(Math.random() * wandererTracks.length)
    const musicTrack = wandererTracks[randomIndex]
    const sound = this.soundEffects[musicTrack]

    if (sound) {
      // Stop ALL music tracks before playing new background music
      this.stopAllMusic()

      // Set state before playing
      this.currentMusicState = 'background'

      // Play the selected track
      sound.play()

      // Track current background music for potential resumption
      this.currentBackgroundMusic = musicTrack
      this.backgroundMusicPosition = 0

      // Mark this level as having music played
      this.levelsWithMusic.add(levelKey)

      console.log(`Playing background music: ${musicTrack} for level ${level} (${theme})`)
    } else {
      console.warn(`Background music track not found: ${musicTrack}`)
    }
  },

  stopBackgroundMusic() {
    // Stop ALL music tracks
    this.stopAllMusic()

    // Clear the levels tracking to allow music to play again on new levels
    this.levelsWithMusic.clear()

    // Clear current background music tracking
    this.currentBackgroundMusic = null
    this.backgroundMusicPosition = 0

    console.log("All music stopped")
  },

  stopAllBackgroundMusic() {
    // Stop all wanderer tracks
    this.soundEffects.dungeon_wanderer1.stop()
    this.soundEffects.dungeon_wanderer2.stop()
    this.soundEffects.dungeon_wanderer3.stop()
    this.soundEffects.dungeon_wanderer4.stop()
    this.soundEffects.dungeon_wanderer5.stop()
  },

  stopAllMusic() {
    // Comprehensive function to stop ALL music tracks (background, combat, death)
    // This prevents multiple music tracks from playing simultaneously
    this.soundEffects.dungeon_wanderer1.stop()
    this.soundEffects.dungeon_wanderer2.stop()
    this.soundEffects.dungeon_wanderer3.stop()
    this.soundEffects.dungeon_wanderer4.stop()
    this.soundEffects.dungeon_wanderer5.stop()
    this.soundEffects.dungeon_fight1.stop()
    this.soundEffects.dungeon_death.stop()

    // Reset music state
    this.currentMusicState = 'none'

    console.log("🔇 All music tracks stopped (safety check)")
  },

  playDeathMusic() {
    // Ensure audio context is ready before playing
    if (!this.audioInitialized) {
      console.warn("Audio not yet initialized - waiting for user interaction")
      return
    }

    // Prevent duplicate death music starts
    if (this.currentMusicState === 'death') {
      console.log("🚫 Death music already playing, ignoring duplicate start request")
      return
    }

    // Stop ALL music tracks before playing death music
    this.stopAllMusic()

    // Set state before playing
    this.currentMusicState = 'death'

    // Play death music
    const sound = this.soundEffects.dungeon_death
    if (sound) {
      sound.play()
      console.log("Playing death music")
    } else {
      console.warn("Death music track not found")
    }
  },

  playCombatMusic() {
    // Ensure audio context is ready before playing
    if (!this.audioInitialized) {
      console.warn("Audio not yet initialized - waiting for user interaction")
      return
    }

    // Prevent duplicate combat music starts
    if (this.currentMusicState === 'combat') {
      console.log("🚫 Combat music already playing, ignoring duplicate start request")
      return
    }

    // Store current background music position for resumption
    if (this.currentBackgroundMusic) {
      const currentSound = this.soundEffects[this.currentBackgroundMusic]
      if (currentSound && currentSound.playing()) {
        this.backgroundMusicPosition = currentSound.seek()
      }
    }

    // Stop ALL music tracks before playing combat music
    this.stopAllMusic()

    // Set state before playing
    this.currentMusicState = 'combat'

    // Play combat music
    const sound = this.soundEffects.dungeon_fight1
    if (sound) {
      sound.play()
      console.log("Playing combat music")
    } else {
      console.warn("Combat music track not found")
    }
  },

  resumeBackgroundMusic() {
    // Ensure audio context is ready before playing
    if (!this.audioInitialized) {
      console.warn("Audio not yet initialized - waiting for user interaction")
      return
    }

    // Prevent duplicate background music resumption
    if (this.currentMusicState === 'background') {
      return
    }

    // Stop combat and death music (but preserve background music state for resumption)
    this.soundEffects.dungeon_fight1.stop()
    this.soundEffects.dungeon_death.stop()

    // Resume background music if there was one playing
    if (this.currentBackgroundMusic) {
      const sound = this.soundEffects[this.currentBackgroundMusic]
      if (sound) {
        // Set state before resuming
        this.currentMusicState = 'background'

        // Resume from where it left off
        sound.seek(this.backgroundMusicPosition)
        sound.play()
        console.log(`Resuming background music: ${this.currentBackgroundMusic} at position ${this.backgroundMusicPosition}`)
      } else {
        console.warn(`Background music track not found: ${this.currentBackgroundMusic}`)
      }
    }
  },

  destroyed() {
    // Stop ALL music tracks
    this.stopAllMusic()

    // Clean up audio resources
    Object.values(this.soundEffects).forEach(sound => {
      sound.unload()
    })
  }
}

// Image Preloader Hook - ensures preloading is active and validates on LiveView
Hooks.ImagePreloader = {
  mounted() {
    console.log('🎮 LiveView mounted, checking image availability...')

    // Always wait for preloading to finish before verifying
    const waitForPreloading = () => {
      if (window.dungeonImagePreloading.completed) {
        this.verifyImages()
      } else if (window.dungeonImagePreloading.promise) {
        window.dungeonImagePreloading.promise.then(() => {
          setTimeout(() => this.verifyImages(), 500)
        })
      } else {
        // If preloading never started, start it now
        window.dungeonImagePreloading.promise = startImagePreloading()
        window.dungeonImagePreloading.promise.then(() => {
          setTimeout(() => this.verifyImages(), 500)
        })
      }
    }

    waitForPreloading()
  },

  async verifyImages() {
    try {
      const result = await imagePreloader.verifyImageAvailability()

      const indicators = document.querySelectorAll('.image-preload-status')
      indicators.forEach(indicator => {
        if (result.unavailable === 0) {
          indicator.textContent = 'All images verified!'
          indicator.style.color = '#10b981'
        } else {
          indicator.textContent = `Images loading... (${result.unavailable} missing)`
          indicator.style.color = '#f59e0b'
        }
      })

      if (result.unavailable > 0) {
        console.log(`🔄 Loaded ${result.unavailable} missing images in LiveView`)
      }
    } catch (error) {
      console.error('Failed to verify images:', error)
    }
  }
}

Hooks.PathfindingHook = {
  mounted() {
    this.movementQueue = []
    this.isMoving = false
    this.currentPath = []
    this.destinationHighlight = null
    this.pathHighlights = []

    // Attach click handler directly to the hook element (dungeon grid)
    this.dungeonGrid = this.el
    this.handleClick = this.enhancedOnMapClick.bind(this)
    this.dungeonGrid.addEventListener('click', this.handleClick)

    // Load initial data from data attributes
    this.loadWalkabilityData()

    // Listen for movement completion from LiveView
    this.handleEvent("movement_completed", () => {
      console.log('✅ PathfindingHook: Movement completed, processing next move')
      this.isMoving = false
      this.processNextMove()
    })

    // Listen for walkability updates from LiveView
    this.handleEvent("update_walkability", (data) => {
      console.log('🔄 PathfindingHook: Received walkability update', {
        playerPosition: data.playerPosition,
        viewportX: data.viewportX,
        viewportY: data.viewportY,
        gridSize: `${data.width}x${data.height}`
      })

      this.walkabilityGrid = data.walkability
      this.playerPosition = data.playerPosition // Already in {x, y} format
      this.gridWidth = data.width
      this.gridHeight = data.height
      this.tileSize = data.tileSize || 48
      this.viewportX = data.viewportX || 0
      this.viewportY = data.viewportY || 0
    })

    // Listen for movement interruption (WASD override)
    this.handleEvent("movement_interrupted", () => {
      this.clearMovementQueue()
    })

    // Listen for pathfinding reset (after torch expiration)
    this.handleEvent("reset_pathfinding", () => {
      console.log('🔄 PathfindingHook: Resetting pathfinding state (preserving movement queue)')
      // DON'T clear movement queue - let ongoing movement continue
      // this.clearMovementQueue()
      // Force reload of walkability data from DOM
      this.loadWalkabilityData()
    })

    // Setup scroll behavior enhancements
    this.setupScrollBehavior()

    console.log("PathfindingHook mounted")
  },

  setupScrollBehavior() {
    // Track touch/scroll state to prevent accidental clicks during scrolling
    this.isScrolling = false
    this.touchStartX = 0
    this.touchStartY = 0

    // Handle touch scrolling detection
    this.el.addEventListener('touchstart', (e) => {
      if (e.touches.length === 1) {
        this.touchStartX = e.touches[0].clientX
        this.touchStartY = e.touches[0].clientY
        this.isScrolling = false
      }
    }, { passive: true })

    this.el.addEventListener('touchmove', (e) => {
      if (e.touches.length === 1) {
        const deltaX = Math.abs(e.touches[0].clientX - this.touchStartX)
        const deltaY = Math.abs(e.touches[0].clientY - this.touchStartY)

        // If user moved more than 10px, consider it scrolling
        if (deltaX > 10 || deltaY > 10) {
          this.isScrolling = true
        }
      }
    }, { passive: true })

    this.el.addEventListener('touchend', () => {
      // Reset scrolling state after a short delay
      setTimeout(() => {
        this.isScrolling = false
      }, 100)
    }, { passive: true })

    // Handle mouse wheel scrolling
    this.el.addEventListener('wheel', (e) => {
      // Allow default scrolling behavior
      e.stopPropagation()
    }, { passive: true })
  },

  enhancedOnMapClick(event) {
    // Ignore clicks that were part of scrolling gestures
    if (this.isScrolling) {
      console.log('🚫 Click ignored - was part of scrolling gesture')
      return
    }

    // Call the original click handler
    this.originalOnMapClick(event)
  },

  loadWalkabilityData() {
    try {
      const walkabilityData = this.el.dataset.walkability
      const playerPositionData = this.el.dataset.playerPosition

      if (walkabilityData) {
        this.walkabilityGrid = JSON.parse(walkabilityData)
      }
      if (playerPositionData) {
        const posArray = JSON.parse(playerPositionData)
        this.playerPosition = { x: posArray[0], y: posArray[1] }
      }

      this.gridWidth = parseInt(this.el.dataset.gridWidth) || 0
      this.gridHeight = parseInt(this.el.dataset.gridHeight) || 0
      this.tileSize = 48 // Fixed tile size
      this.viewportX = parseInt(this.el.dataset.viewportX) || 0
      this.viewportY = parseInt(this.el.dataset.viewportY) || 0

      console.log('Walkability data loaded:', {
        gridWidth: this.gridWidth,
        gridHeight: this.gridHeight,
        playerPosition: this.playerPosition,
        viewportX: this.viewportX,
        viewportY: this.viewportY
      })
    } catch (error) {
      console.error('Error loading walkability data:', error)
    }
  },

  originalOnMapClick(event) {
    // Prevent default click behavior
    event.preventDefault()
    event.stopPropagation()

    // Try to get grid coordinates from data-x and data-y attributes
    let tileEl = event.target.closest('[data-x][data-y]');
    let x, y;
    if (tileEl) {
      x = parseInt(tileEl.getAttribute('data-x'), 10);
      y = parseInt(tileEl.getAttribute('data-y'), 10);
    } else {
      // Fallback to pixelToGrid if not clicking a tile
      const gridPos = this.pixelToGrid(event.offsetX, event.offsetY, event);
      if (!gridPos) return;
      x = gridPos.x;
      y = gridPos.y;
    }

    // Always clear movement queue before starting a new path
    this.clearMovementQueue();

    // Check if destination is walkable
    if (!this.isWalkable(x, y)) {
      console.log(`🚫 PathfindingHook: Tile (${x}, ${y}) not walkable`, {
        hasWalkabilityGrid: !!this.walkabilityGrid,
        gridSize: this.walkabilityGrid ? `${this.walkabilityGrid[0]?.length}x${this.walkabilityGrid.length}` : 'none',
        playerPosition: this.playerPosition
      })

      // NEW: Check for a walkable neighbor if the target is unwalkable
      const walkableNeighbor = this.findWalkableNeighbor(x, y);
      if (walkableNeighbor) {
        console.log(`✅ PathfindingHook: Found walkable neighbor at (${walkableNeighbor.x}, ${walkableNeighbor.y})`)
        // Set the destination to the walkable neighbor
        x = walkableNeighbor.x;
        y = walkableNeighbor.y;
      } else {
        console.log(`❌ PathfindingHook: No walkable neighbor found for (${x}, ${y})`)
        return; // Still unwalkable, do nothing
      }
    }

    // Find path from current player position to clicked position
    let path = this.findPath(this.playerPosition, { x, y });

    // Limit path length to 12 tiles (including starting tile)
    if (path && path.length > 12) {
      path = path.slice(0, 12);
    }

    if (path && path.length > 1) {
      // Remove the first position (current player position)
      const movePath = path.slice(1);

      // Set new path
      this.movementQueue = movePath;
      this.currentPath = path;

      // Update visual highlights
      this.updatePathHighlights(path, { x, y });

      // Start processing the movement queue
      this.processNextMove();

      console.log(`Pathfinding: Found path with ${movePath.length} moves`);
    } else {
      console.log(`Pathfinding: No path found to (${x}, ${y})`);
    }
  },

  pixelToGrid(pixelX, pixelY, event = null) {
    // Account for padding around the grid (p-1 = 4px on mobile, lg:p-4 = 16px on desktop)
    const isLargeScreen = window.innerWidth >= 1024 // lg breakpoint
    const padding = isLargeScreen ? 16 : 4

    // Get bounding rect of the grid element
    const rect = this.el.getBoundingClientRect()

    // Calculate coordinates relative to the grid element
    let relX = pixelX
    let relY = pixelY
    if (event && event.clientX !== undefined && event.clientY !== undefined) {
      relX = event.clientX - rect.left
      relY = event.clientY - rect.top
    }

    // Subtract padding from click coordinates
    const adjustedX = relX - padding
    const adjustedY = relY - padding

    // Calculate grid position based on tile size and viewport offset
    let gridX = Math.floor(adjustedX / this.tileSize) + this.viewportX
    const gridY = Math.floor(adjustedY / this.tileSize) + this.viewportY

    // Optionally flip X coordinate if grid is mirrored
    const flipX = true // Set to true if you want to flip X axis
    if (flipX) {
      gridX = (this.gridWidth - 1) - gridX
    }

    // Debug: log all values
    console.log('🔍 JS DEBUG: pixelToGrid', {
      pixelX,
      pixelY,
      relX,
      relY,
      adjustedX,
      adjustedY,
      gridX,
      gridY,
      tileSize: this.tileSize,
      viewportX: this.viewportX,
      viewportY: this.viewportY,
      gridWidth: this.gridWidth,
      gridHeight: this.gridHeight,
      rect
    })

    // Check bounds
    if (gridX < 0 || gridX >= this.gridWidth || gridY < 0 || gridY >= this.gridHeight) {
      return null
    }

    return { x: gridX, y: gridY }
  },

  isWalkable(x, y) {
    if (!this.walkabilityGrid) {
      return false
    }

    if (y < 0 || y >= this.walkabilityGrid.length) {
      return false
    }

    if (x < 0 || x >= this.walkabilityGrid[y].length) {
      return false
    }

    const walkable = this.walkabilityGrid[y][x]
    return walkable
  },

  findWalkableNeighbor(x, y) {
    // Check 4 adjacent tiles (up, down, left, right) for walkable neighbors
    const neighbors = [
      { x: x + 1, y: y },     // right
      { x: x - 1, y: y },     // left
      { x: x, y: y + 1 },     // down
      { x: x, y: y - 1 }      // up
    ];

    for (const neighbor of neighbors) {
      if (this.isWalkable(neighbor.x, neighbor.y)) {
        return neighbor;
      }
    }

    return null; // No walkable neighbor found
  },

  findPath(start, end) {
    // A* pathfinding algorithm
    const openSet = [{ ...start, g: 0, h: this.manhattanDistance(start, end), f: 0 }]
    const closedSet = new Set()
    const cameFrom = new Map()

    openSet[0].f = openSet[0].g + openSet[0].h

    while (openSet.length > 0) {
      // Find node with lowest f score
      let current = openSet[0]
      let currentIndex = 0

      for (let i = 1; i < openSet.length; i++) {
        if (openSet[i].f < current.f) {
          current = openSet[i]
          currentIndex = i
        }
      }

      // Remove current from open set
      openSet.splice(currentIndex, 1)

      // Add current to closed set
      const currentKey = `${current.x},${current.y}`
      closedSet.add(currentKey)

      // Check if we reached the goal
      if (current.x === end.x && current.y === end.y) {
        // Reconstruct path
        const path = []
        let node = current

        while (node) {
          path.unshift({ x: node.x, y: node.y })
          const nodeKey = `${node.x},${node.y}`
          node = cameFrom.get(nodeKey)
        }

        return path
      }

      // Check all neighbors (4-directional movement)
      const neighbors = [
        { x: current.x + 1, y: current.y },
        { x: current.x - 1, y: current.y },
        { x: current.x, y: current.y + 1 },
        { x: current.x, y: current.y - 1 }
      ]

      for (const neighbor of neighbors) {
        const neighborKey = `${neighbor.x},${neighbor.y}`

        // Skip if already evaluated or not walkable
        if (closedSet.has(neighborKey) || !this.isWalkable(neighbor.x, neighbor.y)) {
          continue
        }

        const tentativeG = current.g + 1

        // Check if this neighbor is already in open set
        let neighborNode = openSet.find(node => node.x === neighbor.x && node.y === neighbor.y)

        if (!neighborNode) {
          // Add new node to open set
          neighborNode = {
            x: neighbor.x,
            y: neighbor.y,
            g: tentativeG,
            h: this.manhattanDistance(neighbor, end),
            f: 0
          }
          neighborNode.f = neighborNode.g + neighborNode.h
          openSet.push(neighborNode)
          cameFrom.set(neighborKey, current)
        } else if (tentativeG < neighborNode.g) {
          // Update existing node with better path
          neighborNode.g = tentativeG
          neighborNode.f = neighborNode.g + neighborNode.h
          cameFrom.set(neighborKey, current)
        }
      }
    }

    // No path found
    return null
  },

  manhattanDistance(a, b) {
    return Math.abs(a.x - b.x) + Math.abs(a.y - b.y)
  },

  processNextMove() {
    if (this.isMoving || this.movementQueue.length === 0) {
      if (this.movementQueue.length === 0) {
        console.log('🏁 PathfindingHook: Movement queue empty, clearing highlights')
        this.clearPathHighlights()
      }
      return
    }

    const nextPosition = this.movementQueue.shift()
    this.isMoving = true

    console.log(`🚶 PathfindingHook: Moving to (${nextPosition.x}, ${nextPosition.y}), ${this.movementQueue.length} moves remaining`)

    // Send move command to LiveView with pathfinding flag
    // Only show dialogs for the final destination, not intermediate tiles
    const isFinalDestination = this.movementQueue.length === 0
    this.pushEvent("move_player", {
      x: nextPosition.x.toString(),
      y: nextPosition.y.toString(),
      pathfinding: !isFinalDestination
    })
  },

  clearMovementQueue() {
    this.movementQueue = []
    this.currentPath = []
    this.isMoving = false
    this.clearPathHighlights()
  },

  updatePathHighlights(path, destination) {
    this.clearPathHighlights()

    // Add destination highlight
    const destElement = this.findTileElement(destination.x, destination.y)
    if (destElement) {
      destElement.classList.add('pathfinding-destination')
      this.destinationHighlight = destElement
    }

    // Add path highlights (skip start and end positions)
    for (let i = 1; i < path.length - 1; i++) {
      const pos = path[i]
      const element = this.findTileElement(pos.x, pos.y)
      if (element) {
        element.classList.add('pathfinding-path')
        this.pathHighlights.push(element)
      }
    }
  },

  clearPathHighlights() {
    // Clear destination highlight
    if (this.destinationHighlight) {
      this.destinationHighlight.classList.remove('pathfinding-destination')
      this.destinationHighlight = null
    }

    // Clear path highlights
    this.pathHighlights.forEach(element => {
      element.classList.remove('pathfinding-path')
    })
    this.pathHighlights = []
  },

  findTileElement(x, y) {
    // Find tile element by data attributes within the grid
    return this.dungeonGrid.querySelector(`[phx-value-x="${x}"][phx-value-y="${y}"]`)
  },

  destroyed() {
    if (this.dungeonGrid && this.handleClick) {
      this.dungeonGrid.removeEventListener('click', this.handleClick)
    }
    this.clearPathHighlights()
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  // Forward key repeat so the server can ignore OS auto-repeat (avoids move spam on held WASD)
  metadata: {
    keydown: (e, _el) => ({ repeat: e.repeat })
  }
})

// Touch gesture handling for mobile
let touchStartX = 0
let touchStartY = 0
let touchEndX = 0
let touchEndY = 0

// Minimum swipe distance to trigger movement
const SWIPE_THRESHOLD = 50

function handleTouchStart(e) {
  touchStartX = e.touches[0].clientX
  touchStartY = e.touches[0].clientY
}

function handleTouchEnd(e) {
  touchEndX = e.changedTouches[0].clientX
  touchEndY = e.changedTouches[0].clientY
  handleSwipeGesture()
}

function handleSwipeGesture() {
  const deltaX = touchEndX - touchStartX
  const deltaY = touchEndY - touchStartY

  // Only process if swipe is significant enough
  if (Math.abs(deltaX) < SWIPE_THRESHOLD && Math.abs(deltaY) < SWIPE_THRESHOLD) {
    return
  }

  // Determine direction - prioritize the larger delta
  let direction = null
  if (Math.abs(deltaX) > Math.abs(deltaY)) {
    // Horizontal swipe
    direction = deltaX > 0 ? 'd' : 'a' // right or left
  } else {
    // Vertical swipe  
    direction = deltaY > 0 ? 's' : 'w' // down or up
  }

  // Send keydown event to LiveView
  if (direction) {
    const dungeonMap = document.getElementById('dungeon-map')
    if (dungeonMap) {
      dungeonMap.dispatchEvent(new KeyboardEvent('keydown', {
        key: direction,
        bubbles: true
      }))
    }
  }
}

// Add touch event listeners when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
  const dungeonMap = document.getElementById('dungeon-map')
  if (dungeonMap) {
    dungeonMap.addEventListener('touchstart', handleTouchStart, { passive: true })
    dungeonMap.addEventListener('touchend', handleTouchEnd, { passive: true })

    // Prevent default touch behaviors on the map to avoid scrolling
    dungeonMap.addEventListener('touchmove', function (e) {
      e.preventDefault()
    }, { passive: false })
  }
})



// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Handle opening URLs in new tabs
window.addEventListener("phx:open_url", (e) => {
  window.open(e.detail.url, '_blank')
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

