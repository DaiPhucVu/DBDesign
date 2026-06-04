<template>
  <div class="container py-4" style="max-width:600px">
    <h1 class="mb-4 text-center">Score Entry</h1>

    <!-- setup screen -->
    <div v-if="!sessionActive && !sessionDone" class="card p-3 mb-3">
      <div class="mb-3">
        <label class="form-label fw-semibold">Round</label>
        <select v-model.number="selectedRound" class="form-select" @change="onRoundChange">
          <option :value="null" disabled>Select a round...</option>
          <option v-for="r in rounds" :key="r.RoundID" :value="r.RoundID">
            {{ r.RoundName }} ({{ r.TotalEnds }} ends)
          </option>
        </select>
      </div>
      <div class="mb-3">
        <label class="form-label fw-semibold">Archer</label>
        <select v-model.number="selectedArcher" class="form-select">
          <option :value="null" disabled>Select an archer...</option>
          <option v-for="a in archers" :key="a.ArcherID" :value="a.ArcherID">
            {{ a.Fname }} {{ a.Lname }}
          </option>
        </select>
      </div>
      <div v-if="currentArcher" class="mb-3">
        <label class="form-label fw-semibold">Equipment</label>
        <select v-model.number="selectedEquipment" class="form-select">
          <option v-for="e in equipment" :key="e.EquipmentID" :value="e.EquipmentID">
            {{ e.EquipmentName }}
          </option>
        </select>
      </div>
      <button class="btn btn-primary w-100" :disabled="!selectedRound || !selectedArcher" @click="startEntry">
        Start
      </button>
    </div>

    <!-- active session -->
    <div v-if="sessionActive && !sessionDone">
      <div class="card p-3 mb-3">
        <div class="d-flex justify-content-between">
          <div>
            <strong>{{ currentArcher?.Fname }} {{ currentArcher?.Lname }}</strong>
            <div class="text-muted small">{{ currentRound?.RoundName }} — {{ currentEquipmentName }}</div>
          </div>
          <div class="text-end">
            <div class="fs-5 fw-bold">{{ runningTotal }}</div>
            <div class="text-muted small">running total</div>
          </div>
        </div>
      </div>

      <div class="card p-3 mb-3">
        <div v-for="(range, ri) in ranges" :key="ri" class="mb-2">
          <div class="text-muted small mb-1">Range {{ range.SequenceNo }} — {{ range.Distance }}m / {{ range.TargetFace }}cm face</div>
          <div class="d-flex flex-wrap gap-2">
            <div
              v-for="en in range.Ends"
              :key="en"
              class="end-chip"
              :class="endChipClass(ri, en)"
              @click="openEnd(ri, en)"
            >
              <div class="end-num">{{ globalEndNumber(ri, en) }}</div>
              <div class="end-score">{{ getEndScore(ri, en) }}</div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="!showDialog" class="alert alert-info">
        {{ promptText }}
      </div>
    </div>

    <!-- done screen -->
    <div v-if="sessionDone" class="card p-3 text-center">
      <div class="fs-1 mb-2">🎯</div>
      <h4>Round complete</h4>
      <div class="mb-1">{{ currentArcher?.Fname }} {{ currentArcher?.Lname }}</div>
      <div class="mb-1">{{ currentRound?.RoundName }}</div>
      <div class="fs-2 fw-bold my-3">{{ runningTotal }}</div>
      <div class="text-muted small mb-3">out of {{ currentRound?.MaxScore }}</div>
      <div class="list-group list-group-flush mb-3">
        <div class="list-group-item d-flex justify-content-between small" v-for="e in allEndResults" :key="e.globalNo">
          <span>End {{ e.globalNo }} (Range {{ e.rangeNo }}, {{ e.distance }}m)</span>
          <strong>{{ e.total }}</strong>
        </div>
      </div>
      <button class="btn btn-outline-primary" @click="resetSession">Start new score</button>
    </div>

    <!-- score entry dialog -->
    <div v-if="showDialog" class="score-overlay">
      <div class="score-card">
        <div class="text-center mb-2">
          <strong>{{ currentArcher?.Fname }} {{ currentArcher?.Lname }}</strong>
          <div class="text-muted small">{{ activeRangeInfo?.Distance }}m / {{ activeRangeInfo?.TargetFace }}cm</div>
          <div class="small">End {{ globalEndNumber(activeRangeIdx, activeEndNo) }} of {{ totalEnds }}</div>
        </div>

        <div class="d-flex gap-1 justify-content-center mb-2 flex-wrap">
          <span v-for="s in shots" :key="s.pos" class="arrow-pill" :class="s.label === 'X' ? 'pill-x' : ''">
            {{ s.label }}
          </span>
          <span v-for="i in (6 - shots.length)" :key="'empty'+i" class="arrow-pill pill-empty">—</span>
        </div>

        <div class="text-center mb-2">
          End total: <strong>{{ endTotal }}</strong>
        </div>

        <div class="btn-grid mb-3">
          <button
            v-for="b in buttons"
            :key="b.label"
            class="btn btn-score"
            :class="isDisabled(b) ? 'btn-outline-secondary disabled-btn' : 'btn-outline-dark'"
            :disabled="isDisabled(b) || shots.length >= 6"
            @click="addShot(b)"
          >
            {{ b.label }}
          </button>
        </div>

        <div class="d-flex gap-2 justify-content-center">
          <button class="btn btn-sm btn-secondary" @click="undoShot" :disabled="shots.length === 0">Undo</button>
          <button class="btn btn-sm btn-primary" @click="saveEnd" :disabled="shots.length === 0">Save</button>
          <button class="btn btn-sm btn-light" @click="closeDialog">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const rounds = ref([])
const archers = ref([])
const equipment = ref([])
const ranges = ref([])

const selectedRound = ref(null)
const selectedArcher = ref(null)
const selectedEquipment = ref(null)

const sessionActive = ref(false)
const sessionDone = ref(false)
const currentRecordId = ref(null)
const runningTotal = ref(0)
const allEndResults = ref([])

const showDialog = ref(false)
const shots = ref([])
const activeRangeIdx = ref(0)
const activeEndNo = ref(1)

// X counts as 10, M is a miss (0) — order is highest first per the rules
const buttons = [
  { label: 'X', score: 10, isX: true },
  { label: '10', score: 10 },
  { label: '9', score: 9 },
  { label: '8', score: 8 },
  { label: '7', score: 7 },
  { label: '6', score: 6 },
  { label: '5', score: 5 },
  { label: '4', score: 4 },
  { label: '3', score: 3 },
  { label: '2', score: 2 },
  { label: '1', score: 1 },
  { label: 'M', score: 0 }
]

const currentRound = computed(() => rounds.value.find(r => r.RoundID === selectedRound.value))
const currentArcher = computed(() => archers.value.find(a => a.ArcherID === selectedArcher.value))
const activeRangeInfo = computed(() => ranges.value[activeRangeIdx.value])
const currentEquipmentName = computed(() => equipment.value.find(e => e.EquipmentID === selectedEquipment.value)?.EquipmentName || '')
const totalEnds = computed(() => ranges.value.reduce((sum, r) => sum + r.Ends, 0))
const endTotal = computed(() => shots.value.reduce((s, a) => s + a.numeric, 0))

// once you enter a score, anything higher than it gets disabled
// this forces descending order like the brief requires
const lowestSoFar = computed(() => {
  if (shots.value.length === 0) return Infinity
  return Math.min(...shots.value.map(s => s.numeric))
})

const isDisabled = (b) => b.score > lowestSoFar.value

// figures out which overall end number we're on across all ranges
const globalEndNumber = (rangeIdx, endNo) => {
  let offset = 0
  for (let i = 0; i < rangeIdx; i++) offset += ranges.value[i]?.Ends || 0
  return offset + endNo
}

const getEndScore = (rangeIdx, endNo) => {
  const found = allEndResults.value.find(e => e.rangeIdx === rangeIdx && e.endNo === endNo)
  return found ? found.total : null
}

const isEndDone = (rangeIdx, endNo) => getEndScore(rangeIdx, endNo) !== null

const nextUndoneEnd = computed(() => {
  for (let ri = 0; ri < ranges.value.length; ri++) {
    for (let en = 1; en <= ranges.value[ri].Ends; en++) {
      if (!isEndDone(ri, en)) return { ri, en }
    }
  }
  return null
})

const promptText = computed(() => {
  if (!nextUndoneEnd.value) return 'All ends complete!'
  const { ri, en } = nextUndoneEnd.value
  const r = ranges.value[ri]
  return `Tap end ${globalEndNumber(ri, en)} to enter — Range ${r.SequenceNo}, ${r.Distance}m on ${r.TargetFace}cm face`
})

const endChipClass = (ri, en) => {
  if (isEndDone(ri, en)) return 'chip-done'
  const next = nextUndoneEnd.value
  if (next && next.ri === ri && next.en === en) return 'chip-next'
  return 'chip-pending'
}

const fetchRounds = async () => {
  const res = await fetch('/api/rounds')
  rounds.value = await res.json()
}

const fetchArchers = async () => {
  const res = await fetch('/api/archers')
  archers.value = await res.json()
}

const fetchEquipment = async () => {
  const res = await fetch('/api/equipment')
  equipment.value = await res.json()
}

const fetchRanges = async (roundId) => {
  const res = await fetch(`/api/rounds/${roundId}/ranges`)
  ranges.value = await res.json()
}

const onRoundChange = () => {
  if (selectedRound.value) fetchRanges(selectedRound.value)
}

const startEntry = async () => {
  if (!selectedRound.value || !selectedArcher.value) return

  const res = await fetch('/api/records', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      ArcherID: selectedArcher.value,
      RoundID: selectedRound.value,
      EquipmentID: selectedEquipment.value
    })
  })
  if (!res.ok) return alert('Failed to start session')
  const data = await res.json()
  currentRecordId.value = data.RecordID
  sessionActive.value = true
  runningTotal.value = 0
  allEndResults.value = []
}

const openEnd = (ri, en) => {
  if (isEndDone(ri, en)) return
  activeRangeIdx.value = ri
  activeEndNo.value = en
  shots.value = []
  showDialog.value = true
}

const closeDialog = () => { showDialog.value = false }

const addShot = (btn) => {
  if (shots.value.length >= 6) return
  shots.value.push({ pos: shots.value.length + 1, label: btn.label, numeric: btn.score, isX: !!btn.isX })
}

const undoShot = () => { shots.value.pop() }

const saveEnd = async () => {
  if (!currentRecordId.value || shots.value.length === 0) return

  const range = ranges.value[activeRangeIdx.value]
  const arrows = shots.value.map(s => ({
    position: s.pos,
    score: s.label,
    isX: s.isX
  }))

  const res = await fetch(`/api/records/${currentRecordId.value}/ends`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      RangeNo: range.SequenceNo,
      EndNo: activeEndNo.value,
      Arrows: arrows
    })
  })

  if (!res.ok) return alert('Save failed')
  const result = await res.json()

  allEndResults.value.push({
    rangeIdx: activeRangeIdx.value,
    endNo: activeEndNo.value,
    globalNo: globalEndNumber(activeRangeIdx.value, activeEndNo.value),
    rangeNo: range.SequenceNo,
    distance: range.Distance,
    total: result.sum
  })
  runningTotal.value += result.sum
  closeDialog()

  if (!nextUndoneEnd.value) {
    sessionActive.value = false
    sessionDone.value = true
  }
}

const resetSession = () => {
  sessionActive.value = false
  sessionDone.value = false
  selectedRound.value = null
  selectedArcher.value = null
  selectedEquipment.value = null
  ranges.value = []
  allEndResults.value = []
  runningTotal.value = 0
  currentRecordId.value = null
}

onMounted(async () => {
  await Promise.all([fetchRounds(), fetchArchers(), fetchEquipment()])
})
</script>

<style scoped>
.end-chip {
  width: 48px; height: 48px; border-radius: 8px;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  cursor: pointer; font-size: 12px; border: 2px solid transparent;
}
.end-num { font-weight: 600; }
.end-score { font-size: 13px; }
.chip-done    { background: #d1e7dd; border-color: #198754; }
.chip-next    { background: #cfe2ff; border-color: #0d6efd; animation: pulse 1.5s infinite; }
.chip-pending { background: #f8f9fa; border-color: #dee2e6; }

@keyframes pulse {
  0%,100% { border-color: #0d6efd; }
  50%      { border-color: #9ec5fe; }
}

.score-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.45);
  display: flex; align-items: center; justify-content: center; z-index: 100;
}
.score-card {
  background: #fff; border-radius: 12px; padding: 20px; width: 340px; max-width: 95vw;
}
.btn-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.btn-score { font-weight: 600; }
.disabled-btn { opacity: 0.3; }
.arrow-pill {
  display: inline-flex; align-items: center; justify-content: center;
  width: 36px; height: 36px; border-radius: 50%; font-weight: 700; font-size: 13px;
  background: #dee2e6;
}
.pill-x     { background: #ffc107; }
.pill-empty { background: #f8f9fa; color: #adb5bd; }
</style>
