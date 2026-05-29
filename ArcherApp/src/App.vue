<template>
  <div class="container py-4">
    <h1 class="mb-4 text-center">Single Score Entry</h1>

    <div class="card p-3 mb-4">
      <div class="row g-3 align-items-end">
        <div class="col-md-5">
          <label class="form-label">Choose round</label>
          <select v-model.number="selectedRound" class="form-select">
            <option v-for="r in rounds" :key="r.RoundID" :value="r.RoundID">{{ r.RoundName }} ({{ r.TotalEnds }} ends)</option>
          </select>
        </div>
        <div class="col-md-5">
          <label class="form-label">Choose archer</label>
          <select v-model.number="selectedArcher" class="form-select">
            <option v-for="a in archers" :key="a.ArcherID" :value="a.ArcherID">{{ a.Fname }} {{ a.Lname }}</option>
          </select>
        </div>
        <div class="col-md-2 text-end">
          <button class="btn btn-primary" @click="startEntry">Start</button>
        </div>
      </div>
    </div>

    <div v-if="sessionActive" class="card p-3 mb-4">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <div>
          <strong>{{ currentArcher?.Fname }} {{ currentArcher?.Lname }}</strong>
          <div class="text-muted">Round: {{ currentRound?.RoundName }} — {{ totalEnds }} ends</div>
        </div>
        <div>
          <label class="form-label">Equipment</label>
          <select v-model.number="selectedEquipment" class="form-select">
            <option v-for="e in equipment" :key="e.EquipmentID" :value="e.EquipmentID">{{ e.EquipmentName }}</option>
          </select>
        </div>
      </div>

      <div class="mb-2">
        <label class="form-label">Enter end</label>
        <div class="d-flex gap-2">
          <input type="number" v-model.number="currentEndNo" min="1" :max="totalEnds" class="form-control" style="width:120px" />
          <button class="btn btn-outline-secondary" @click="openScoreDialog">Enter score for end</button>
        </div>
      </div>

      <div v-if="message" class="alert alert-success py-2">{{ message }}</div>
    </div>

    <!-- simple visual of entered ends -->
    <div v-if="enteredEnds.length" class="card p-2">
      <h5>Entered Ends</h5>
      <ul class="list-group">
        <li class="list-group-item" v-for="e in enteredEnds" :key="e.EndNo">End {{ e.EndNo }} — Total: {{ e.total }}</li>
      </ul>
    </div>

    <!-- Score dialog -->
    <div v-if="showDialog" class="score-dialog">
      <div class="dialog-card">
        <h5>Enter arrows for End {{ currentEndNo }}</h5>
        <div class="mb-2">Click the arrow buttons (X counts as 10)</div>
        <div class="btn-grid mb-3">
          <button v-for="b in buttons" :key="b.label" class="btn btn-score" @click="addShot(b)">{{ b.label }}</button>
        </div>

        <div class="shots mb-2">Shots: <span v-for="s in shots" :key="s.pos" class="shot-pill">{{ s.score }}</span></div>
        <div class="d-flex gap-2">
          <button class="btn btn-secondary" @click="clearShots">Clear</button>
          <button class="btn btn-primary" @click="saveEnd">Save End</button>
          <button class="btn btn-light" @click="closeDialog">Cancel</button>
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

const selectedRound = ref(null)
const selectedArcher = ref(null)
const selectedEquipment = ref(null)

const sessionActive = ref(false)
const currentRecordId = ref(null)
const message = ref('')
const showDialog = ref(false)
const currentEndNo = ref(1)
const totalEnds = ref(0)
const shots = ref([])
const enteredEnds = ref([])

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

const currentRound = computed(() => rounds.value.find(r => r.RoundID === selectedRound.value))
const currentArcher = computed(() => archers.value.find(a => a.ArcherID === selectedArcher.value))

const startEntry = async () => {
  if (!selectedRound.value || !selectedArcher.value) return alert('Select round and archer')
  selectedEquipment.value = currentArcher.value?.DefaultEquipmentID || equipment.value[0]?.EquipmentID

  // determine total ends
  totalEnds.value = currentRound.value?.TotalEnds || 0

  // create a record
  const res = await fetch('/api/records', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ArcherID: selectedArcher.value, RoundID: selectedRound.value, EquipmentID: selectedEquipment.value })
  })
  if (!res.ok) return alert('Failed to start record')
  const data = await res.json()
  currentRecordId.value = data.RecordID
  sessionActive.value = true
  message.value = 'Session started — enter ends using the dialog.'
}

const openScoreDialog = () => {
  shots.value = []
  showDialog.value = true
}

const closeDialog = () => { showDialog.value = false }

const addShot = (button) => {
  if (shots.value.length >= 6) return
  shots.value.push({ pos: shots.value.length + 1, score: button.label, numeric: button.score, isX: !!button.isX })
}

const clearShots = () => { shots.value = [] }

const saveEnd = async () => {
  if (!currentRecordId.value) return alert('No active record')
  if (shots.value.length === 0) return alert('Add at least one arrow')

  const arrows = shots.value.map(s => ({ position: s.pos, score: s.score === 'M' ? 'M' : s.numeric, isX: !!s.isX }))
  const res = await fetch(`/api/records/${currentRecordId.value}/ends`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ RangeNo: 1, EndNo: currentEndNo.value, Arrows: arrows })
  })
  if (!res.ok) return alert('Save failed')
  const result = await res.json()
  enteredEnds.value.push({ EndNo: currentEndNo.value, total: result.sum })
  message.value = `Saved end ${currentEndNo.value} (total ${result.sum})`
  closeDialog()
}

onMounted(async () => {
  await Promise.all([fetchRounds(), fetchArchers(), fetchEquipment()])
})
</script>

<style>
.score-dialog {
  position: fixed; inset: 0; display:flex; align-items:center; justify-content:center; background:rgba(0,0,0,0.4);
}
.dialog-card { background: #fff; padding:16px; border-radius:8px; width:360px }
.btn-grid { display:flex; flex-wrap:wrap; gap:8px }
.btn-score { min-width:48px }
.shot-pill { display:inline-block; margin-right:6px; padding:4px 8px; background:#eee; border-radius:6px }
</style>
