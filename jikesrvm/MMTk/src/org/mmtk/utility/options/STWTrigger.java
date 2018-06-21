/*
 *  This file is part of the Jikes RVM project (http://jikesrvm.org).
 *
 *  This file is licensed to You under the Eclipse Public License (EPL);
 *  You may not use this file except in compliance with the License. You
 *  may obtain a copy of the License at
 *
 *      http://www.opensource.org/licenses/eclipse-1.0.php
 *
 *  See the COPYRIGHT.txt file distributed with this work for information
 *  regarding copyright ownership.
 */
package org.mmtk.utility.options;

/**
 * STW trigger percentage
 */
public class STWTrigger extends org.vmutil.options.IntOption {
  /**
   * Create the option.
   */
  public STWTrigger() {
    super(Options.set, "STW Trigger",
          "STW trigger in pages",
          0);
  }

  /**
   * Only accept valid values
   */
  @Override
  protected void validate() {
    failIf(this.value <= -1, "Trigger must be greater than or equal to 0");
  }
}
