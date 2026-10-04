import { z } from 'zod';

export const noteSchema = z.object({
  id: z.uuid(),
  body: z.string().min(1).max(2000),
  createdAt: z.iso.datetime(),
});
export type Note = z.infer<typeof noteSchema>;

export const createNoteSchema = noteSchema.pick({ body: true });
export type CreateNote = z.infer<typeof createNoteSchema>;

export const noteListSchema = z.array(noteSchema);
