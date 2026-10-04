import { z } from 'zod';

export const signInSchema = z.object({
  email: z.email(),
  password: z.string().min(8, 'Use at least 8 characters'),
});
export type SignIn = z.infer<typeof signInSchema>;

export const signUpSchema = signInSchema.extend({
  name: z.string().min(1, 'Name is required').max(100),
});
export type SignUp = z.infer<typeof signUpSchema>;
