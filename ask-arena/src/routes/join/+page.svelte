<script lang="ts">
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let enteredCode = '';
  let userName = '';
  let isJoining = false;
  let errorMessage = '';

  const joinEvent = async () => {
    isJoining = true;
    errorMessage = '';

    try {
      const normalizedCode = enteredCode.trim().toUpperCase();

      const { data, error } = await supabase
        .from('events')
        .select('id, code')
        .eq('code', normalizedCode)
        .maybeSingle();

      if (error) {
        throw error;
      }

      if (!data) {
        errorMessage = 'Event code not found.';
        return;
      }

      const nameParam = encodeURIComponent(userName.trim());
      await goto(`/event/${normalizedCode}/attendee?name=${nameParam}`);
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to join event.';
    } finally {
      isJoining = false;
    }
  };
</script>

<main class="min-h-screen bg-slate-50 px-4 py-12">
  <div class="mx-auto max-w-xl rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
    <h1 class="text-2xl font-bold text-slate-900">Join Event</h1>
    <p class="mt-2 text-sm text-slate-600">Enter your event code and name to join the live Q&amp;A.</p>

    <form
      class="mt-6 space-y-4"
      onsubmit={(event) => {
        event.preventDefault();
        void joinEvent();
      }}
    >
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700" for="code">Event code</label>
        <input
          id="code"
          type="text"
          required
          maxlength="6"
          bind:value={enteredCode}
          class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm uppercase"
          placeholder="A1B2C3"
        />
      </div>

      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700" for="name">Your name</label>
        <input
          id="name"
          type="text"
          required
          maxlength="60"
          bind:value={userName}
          class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          placeholder="Jordan"
        />
      </div>

      {#if errorMessage}
        <p class="rounded-lg bg-rose-50 px-3 py-2 text-sm text-rose-700">{errorMessage}</p>
      {/if}

      <button
        type="submit"
        disabled={isJoining}
        class="w-full rounded-xl bg-indigo-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-slate-400"
      >
        {isJoining ? 'Joining...' : 'Join Event'}
      </button>
    </form>

    <a href="/" class="mt-5 inline-block text-sm font-medium text-indigo-700 hover:text-indigo-800">Back to home</a>
  </div>
</main>